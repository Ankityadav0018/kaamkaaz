/**
 * Migration 001: Wallet → Credits
 *
 * This script migrates existing data to the new credit-pack system:
 * 1. Renames User.walletBalance → User.referralBalance
 * 2. For Wallet documents: converts balance (paise) → credits (integer)
 *    Conversion: 1 credit = ₹9 urgent fee → balance_paise / 900 (rounded down)
 *
 * This script is IDEMPOTENT — safe to run multiple times.
 * Run with: node backend/migrations/001_wallet_to_credits.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');

async function run() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ Connected to MongoDB');

  const db = mongoose.connection.db;

  // ── Step 1: Rename walletBalance → referralBalance on User documents ─────────
  console.log('\n── Step 1: Migrating User.walletBalance → referralBalance ──');
  const usersWithWalletBalance = await db.collection('users').countDocuments({
    walletBalance: { $exists: true }
  });
  console.log(`   Found ${usersWithWalletBalance} user documents with walletBalance field`);

  if (usersWithWalletBalance > 0) {
    const result = await db.collection('users').updateMany(
      { walletBalance: { $exists: true } },
      [
        {
          $set: {
            referralBalance: '$walletBalance'
          }
        },
        {
          $unset: 'walletBalance'
        }
      ]
    );
    console.log(`   ✅ Migrated ${result.modifiedCount} user documents`);
  } else {
    console.log('   ℹ️  No walletBalance fields found — already migrated or clean');
  }

  // ── Step 2: Migrate Wallet.balance (paise) → credits (integer) ──────────────
  console.log('\n── Step 2: Migrating Wallet.balance (paise) → credits (integer) ──');
  const walletsWithBalance = await db.collection('wallets').countDocuments({
    balance: { $exists: true }
  });
  console.log(`   Found ${walletsWithBalance} wallet documents with balance (paise) field`);

  if (walletsWithBalance > 0) {
    // Get all wallets that still have the old balance field
    const wallets = await db.collection('wallets').find({ balance: { $exists: true } }).toArray();
    let converted = 0;
    let skipped = 0;

    for (const wallet of wallets) {
      const balancePaise = wallet.balance || 0;
      // Convert: 1 credit was worth 900 paise (₹9 per urgent posting)
      // Use floor to not over-credit existing users
      const credits = Math.floor(balancePaise / 900);
      
      // Only migrate if credits field doesn't already exist (idempotency)
      if (wallet.credits === undefined || wallet.credits === null) {
        await db.collection('wallets').updateOne(
          { _id: wallet._id },
          {
            $set: {
              credits: credits,
              is_refundable: false,
              is_transferable: false
            },
            $unset: { balance: '' }
          }
        );
        converted++;
      } else {
        skipped++;
      }
    }
    console.log(`   ✅ Converted ${converted} wallet documents (paise → credits)`);
    if (skipped > 0) console.log(`   ℹ️  Skipped ${skipped} already-migrated documents`);
  } else {
    console.log('   ℹ️  No balance (paise) fields found — already migrated or clean');
  }

  // ── Step 3: Migrate WalletTransaction sources ────────────────────────────────
  console.log('\n── Step 3: Migrating WalletTransaction source enums ──');
  const sourceMapping = {
    'RAZORPAY_TOPUP': 'CREDIT_PACK_PURCHASE',
    'URGENT_JOB_DEDUCTION': 'JOB_POST_DEDUCTION',
    'URGENT_JOB_REFUND': 'JOB_POST_REFUND'
  };

  for (const [oldSource, newSource] of Object.entries(sourceMapping)) {
    const count = await db.collection('wallettransactions').countDocuments({ source: oldSource });
    if (count > 0) {
      await db.collection('wallettransactions').updateMany(
        { source: oldSource },
        { $set: { source: newSource } }
      );
      console.log(`   ✅ Renamed ${count} transactions: ${oldSource} → ${newSource}`);
    }
  }

  // Migrate amount/balanceBefore/balanceAfter → credits/creditsBefore/creditsAfter
  // (for old transactions that used paise)
  const oldStyleTxCount = await db.collection('wallettransactions').countDocuments({
    amount: { $exists: true },
    credits: { $exists: false }
  });

  if (oldStyleTxCount > 0) {
    console.log(`   Found ${oldStyleTxCount} old-style transactions (paise) to convert`);
    const oldTxs = await db.collection('wallettransactions').find({
      amount: { $exists: true },
      credits: { $exists: false }
    }).toArray();

    for (const tx of oldTxs) {
      const credits = tx.source === 'JOB_POST_DEDUCTION'
        ? 1  // Each deduction was exactly 1 urgent job = 1 credit
        : tx.source === 'JOB_POST_REFUND'
        ? 1  // Each refund was 1 credit
        : Math.floor((tx.amount || 0) / 900); // Purchases: convert paise

      await db.collection('wallettransactions').updateOne(
        { _id: tx._id },
        {
          $set: {
            credits: credits,
            creditsBefore: Math.floor((tx.balanceBefore || 0) / 900),
            creditsAfter: Math.floor((tx.balanceAfter || 0) / 900)
          },
          $unset: { amount: '', balanceBefore: '', balanceAfter: '' }
        }
      );
    }
    console.log(`   ✅ Converted ${oldTxs.length} transactions to credit units`);
  } else {
    console.log('   ℹ️  No old-style (paise) transactions found');
  }

  // ── Summary ──────────────────────────────────────────────────────────────────
  console.log('\n── Migration Summary ──');
  const totalUsers = await db.collection('users').countDocuments({ referralBalance: { $exists: true } });
  const totalWallets = await db.collection('wallets').countDocuments({ credits: { $exists: true } });
  const totalTxs = await db.collection('wallettransactions').countDocuments({ credits: { $exists: true } });
  console.log(`   Users with referralBalance: ${totalUsers}`);
  console.log(`   Wallets with credits: ${totalWallets}`);
  console.log(`   Transactions with credits: ${totalTxs}`);
  console.log('\n✅ Migration complete!\n');

  await mongoose.disconnect();
  process.exit(0);
}

run().catch(err => {
  console.error('❌ Migration failed:', err);
  process.exit(1);
});

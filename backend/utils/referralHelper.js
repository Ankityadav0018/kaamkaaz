const mongoose = require('mongoose');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Wallet = require('../models/Wallet');
const WalletTransaction = require('../models/WalletTransaction');

const generateReferralCode = async (name, phone) => {
  let namePart = (name || 'USR').replace(/[^a-zA-Z]/g, '').substring(0, 3).toUpperCase();
  if (namePart.length < 3) {
    namePart = namePart.padEnd(3, 'X');
  }
  
  const phonePart = (phone || '0000').slice(-4);
  
  let isUnique = false;
  let code = '';
  
  while (!isUnique) {
    const randomPart = Math.floor(100 + Math.random() * 900).toString();
    code = `${namePart}${phonePart}${randomPart}`;
    
    const existing = await User.findOne({ referralCode: code });
    if (!existing) {
      isUnique = true;
    }
  }
  
  return code;
};

const applyReferralReward = async (referrerId, newUserId) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const referrer = await User.findById(referrerId).session(session);
    const newUser = await User.findById(newUserId).session(session);

    if (!referrer || !newUser) {
      await session.abortTransaction();
      session.endSession();
      return false;
    }

    // Process Referrer Reward
    referrer.referralEarnings = (referrer.referralEarnings || 0) + 10;
    referrer.referralCount = (referrer.referralCount || 0) + 1;
    await referrer.save({ session });

    if (referrer.role === 'recruiter') {
      const rWallet = await Wallet.findOne({ recruiterId: referrer._id }).session(session);
      if (rWallet) {
        const amountPaise = 1000; // ₹10
        const balanceBefore = rWallet.balance;
        const balanceAfter = balanceBefore + amountPaise;
        
        rWallet.balance = balanceAfter;
        await rWallet.save({ session });
        
        await WalletTransaction.create([{
          walletId: rWallet._id,
          recruiterId: referrer._id,
          type: 'CREDIT',
          amount: amountPaise,
          balanceBefore,
          balanceAfter,
          source: 'REFERRAL_BONUS',
          referenceId: newUser._id.toString(),
          idempotencyKey: `REF_BONUS_${referrer._id}_${newUser._id}`,
          status: 'SUCCESS',
          description: `Reward for referring ${newUser.name || 'a new user'}`
        }], { session });
      }
    } else {
      referrer.walletBalance = (referrer.walletBalance || 0) + 10;
      await referrer.save({ session });
      await Transaction.create([{
        userId: referrer._id,
        type: 'referral_reward',
        amount: 10,
        description: `Reward for referring ${newUser.name || 'a new user'}`,
        status: 'completed'
      }], { session });
    }

    // Process New User Reward
    newUser.referredBy = referrer._id;
    await newUser.save({ session });

    if (newUser.role === 'recruiter') {
      const nWallet = await Wallet.findOne({ recruiterId: newUser._id }).session(session);
      if (nWallet) {
        const amountPaise = 1000; // ₹10
        const balanceBefore = nWallet.balance;
        const balanceAfter = balanceBefore + amountPaise;
        
        nWallet.balance = balanceAfter;
        await nWallet.save({ session });
        
        await WalletTransaction.create([{
          walletId: nWallet._id,
          recruiterId: newUser._id,
          type: 'CREDIT',
          amount: amountPaise,
          balanceBefore,
          balanceAfter,
          source: 'REFERRAL_BONUS',
          referenceId: referrer._id.toString(),
          idempotencyKey: `REF_BONUS_WELCOME_${newUser._id}`,
          status: 'SUCCESS',
          description: `Welcome bonus from referral code`
        }], { session });
      }
    } else {
      newUser.walletBalance = (newUser.walletBalance || 0) + 10;
      await newUser.save({ session });
      await Transaction.create([{
        userId: newUser._id,
        type: 'referral_bonus',
        amount: 10,
        description: `Welcome bonus from referral code`,
        status: 'completed'
      }], { session });
    }

    await session.commitTransaction();
    session.endSession();
    return true;
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error applying referral reward:', error);
    return false;
  }
};

module.exports = { generateReferralCode, applyReferralReward };

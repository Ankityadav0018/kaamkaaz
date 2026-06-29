/**
 * migrateEncryptFields.js — One-time migration script
 *
 * Encrypts all existing plaintext aadhaarNumber values in MongoDB.
 * Run once after deploying the encryption system:
 *
 *   node scripts/migrateEncryptFields.js
 *
 * Safe to run multiple times — already-encrypted values are skipped.
 */

require('dotenv').config();
const mongoose  = require('mongoose');
const User      = require('../models/User');
const { encrypt, isEncrypted } = require('../utils/encryption');

const run = async () => {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ Connected to MongoDB');

  let encrypted = 0;
  let skipped   = 0;
  let errors    = 0;

  // Stream all users to avoid loading everything into memory
  const cursor = User.find({}).cursor();

  for await (const user of cursor) {
    let changed = false;

    // Encrypt worker aadhaarNumber
    if (user.aadhaarNumber && !isEncrypted(user.aadhaarNumber)) {
      try {
        user.aadhaarNumber = encrypt(user.aadhaarNumber);
        changed = true;
      } catch (e) {
        console.error(`❌ Failed to encrypt aadhaar for user ${user._id}:`, e.message);
        errors++;
      }
    } else {
      skipped++;
    }

    // Encrypt recruiter verification aadhaarNumber
    if (user.recruiterVerification?.aadhaarNumber && !isEncrypted(user.recruiterVerification.aadhaarNumber)) {
      try {
        user.recruiterVerification.aadhaarNumber = encrypt(user.recruiterVerification.aadhaarNumber);
        changed = true;
      } catch (e) {
        console.error(`❌ Failed to encrypt recruiter aadhaar for user ${user._id}:`, e.message);
        errors++;
      }
    }

    if (changed) {
      // Use updateOne to bypass pre-save hooks (avoid re-hashing password)
      await User.updateOne({ _id: user._id }, {
        $set: {
          aadhaarNumber: user.aadhaarNumber,
          'recruiterVerification.aadhaarNumber': user.recruiterVerification?.aadhaarNumber
        }
      });
      encrypted++;
    }
  }

  console.log(`\n📊 Migration complete:`);
  console.log(`   Encrypted: ${encrypted}`);
  console.log(`   Skipped (already encrypted or empty): ${skipped}`);
  console.log(`   Errors: ${errors}`);

  await mongoose.disconnect();
  process.exit(0);
};

run().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});

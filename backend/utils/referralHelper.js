const mongoose = require('mongoose');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const UserCredits = require('../models/UserCredits'); // UserCredits model
const CreditTransaction = require('../models/CreditTransaction'); // CreditTransaction model

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

const applyReferralReward = async (referrerId, newUserId, io = null) => {
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

    // Process Referrer Reward (Cash for everyone)
    referrer.referralEarnings = (referrer.referralEarnings || 0) + 5;
    referrer.referralCount = (referrer.referralCount || 0) + 1;
    referrer.referralBalance = (referrer.referralBalance || 0) + 5;
    await referrer.save({ session });

    await Transaction.create([{
      userId: referrer._id,
      type: 'referral_reward',
      amount: 5,
      description: `Referral earnings for referring ${newUser.name || 'a new user'}`,
      status: 'completed'
    }], { session });

    if (referrer.role === 'recruiter') {
      // For recruiters: ALSO add bonus credits to their job posting credits account
      const rCredits = await UserCredits.findOne({ recruiterId: referrer._id }).session(session);
      if (rCredits) {
        const bonusCredits = 1; // 1 bonus credit for referring a new user
        const creditsBefore = rCredits.credits;
        const creditsAfter = creditsBefore + bonusCredits;
        
        rCredits.credits = creditsAfter;
        await rCredits.save({ session });
        
        await CreditTransaction.create([{
          creditsId: rCredits._id,
          recruiterId: referrer._id,
          type: 'CREDIT',
          credits: bonusCredits,
          creditsBefore,
          creditsAfter,
          source: 'REFERRAL_BONUS',
          referenceId: newUser._id.toString(),
          idempotencyKey: `REF_BONUS_${referrer._id}_${newUser._id}`,
          status: 'SUCCESS',
          description: `Referral bonus: 1 credit for referring ${newUser.name || 'a new user'}`
        }], { session });
      }
    }

    // Process New User Reward (Cash for everyone)
    newUser.referredBy = referrer._id;
    newUser.referralBalance = (newUser.referralBalance || 0) + 5;
    await newUser.save({ session });

    await Transaction.create([{
      userId: newUser._id,
      type: 'referral_bonus',
      amount: 5,
      description: `Welcome bonus from referral code`,
      status: 'completed'
    }], { session });

    if (newUser.role === 'recruiter') {
      // For new recruiter: ALSO add bonus credits to their job posting credits account
      const nCredits = await UserCredits.findOne({ recruiterId: newUser._id }).session(session);
      if (nCredits) {
        const bonusCredits = 1; // 1 welcome credit
        const creditsBefore = nCredits.credits;
        const creditsAfter = creditsBefore + bonusCredits;
        
        nCredits.credits = creditsAfter;
        await nCredits.save({ session });
        
        await CreditTransaction.create([{
          creditsId: nCredits._id,
          recruiterId: newUser._id,
          type: 'CREDIT',
          credits: bonusCredits,
          creditsBefore,
          creditsAfter,
          source: 'REFERRAL_BONUS',
          referenceId: referrer._id.toString(),
          idempotencyKey: `REF_BONUS_WELCOME_${newUser._id}`,
          status: 'SUCCESS',
          description: `Welcome bonus: 1 credit from referral code`
        }], { session });
      }
    }

    await session.commitTransaction();
    session.endSession();

    if (io) {
      // Emit real-time wallet update to the referrer
      io.to(referrerId.toString()).emit('referral_update', { 
        message: 'You earned a referral bonus!',
        amount: 5
      });
      // Optionally notify the new user as well
      io.to(newUserId.toString()).emit('referral_update', {
        message: 'Welcome bonus credited!',
        amount: 5
      });
    }

    return true;
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error applying referral reward:', error);
    return false;
  }
};

module.exports = { generateReferralCode, applyReferralReward };

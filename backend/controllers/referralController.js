const User = require('../models/User');
const Transaction = require('../models/Transaction');
const { generateReferralCode, applyReferralReward } = require('../utils/referralHelper');
const { createNotification } = require('../utils/notification');

const MIN_WITHDRAWAL_AMOUNT = 150;
const REFERRAL_BONUS_AMOUNT = 5;

exports.getMyCode = async (req, res) => {

  try {
    let user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: req.t('general.not_found') });
    }

    if (!user.referralCode) {
      user.referralCode = await generateReferralCode(user.name, user.phone);
      await user.save();
    }

    const referralLink = `https://kaamkaaz.app/join?ref=${user.referralCode}`;

    res.status(200).json({
      success: true,
      referralCode: user.referralCode,
      referralLink,
      referralCount: user.referralCount || 0,
      referralEarnings: user.referralEarnings || 0,
      referralBalance: user.referralBalance || 0
    });
  } catch (error) {
    console.error('Error fetching referral code:', error);
    res.status(500).json({ success: false, message: req.t('general.server_error') });
  }
};

exports.getStats = async (req, res) => {

  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: req.t('general.not_found') });
    }

    const referredUsers = await User.find({ referredBy: user._id })
      .select('name createdAt isActive')
      .sort({ createdAt: -1 });

    const formattedUsers = referredUsers.map(u => ({
      name: u.name,
      joinedDate: u.createdAt,
      status: u.isActive ? 'active' : 'inactive'
    }));

    res.status(200).json({
      success: true,
      totalReferrals: user.referralCount || 0,
      totalEarnings: user.referralEarnings || 0,
      referralBalance: user.referralBalance || 0,
      referredUsers: formattedUsers
    });
  } catch (error) {
    console.error('Error fetching referral stats:', error);
    res.status(500).json({ success: false, message: req.t('general.server_error') });
  }
};

exports.applyReferral = async (req, res) => {

  try {
    const { referralCode } = req.body;
    if (!referralCode) {
      return res.status(400).json({ success: false, message: req.t('validation.required_field') });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: req.t('general.not_found') });
    }

    if (user.referredBy) {
      return res.status(400).json({ success: false, message: req.t('referral.already_used') });
    }

    const referrer = await User.findOne({ referralCode: new RegExp(`^${referralCode}$`, 'i') });
    if (!referrer) {
      return res.status(404).json({ success: false, message: req.t('referral.invalid_code') });
    }

    if (referrer._id.toString() === user._id.toString()) {
      return res.status(400).json({ success: false, message: req.t('referral.own_code') });
    }

    const applied = await applyReferralReward(referrer._id, user._id);
    if (applied) {
      res.status(200).json({ success: true, bonusEarned: REFERRAL_BONUS_AMOUNT });
    } else {
      res.status(500).json({ success: false, message: req.t('referral.apply_failed') });
    }
  } catch (error) {
    console.error('Error applying referral:', error);
    res.status(500).json({ success: false, message: req.t('general.server_error') });
  }
};

exports.getTransactions = async (req, res) => {

  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const skip = (page - 1) * limit;

    const transactions = await Transaction.find({ userId: req.user.id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Transaction.countDocuments({ userId: req.user.id });

    res.status(200).json({
      success: true,
      transactions,
      totalPages: Math.ceil(total / limit),
      currentPage: page
    });
  } catch (error) {
    console.error('Error fetching transactions:', error);
    res.status(500).json({ success: false, message: req.t('general.server_error') });
  }
};

exports.requestWithdrawal = async (req, res) => {

  try {
    const { amount, upiId } = req.body;

    if (!amount || amount < MIN_WITHDRAWAL_AMOUNT) {
      return res.status(400).json({ success: false, message: req.t('referral.min_withdrawal', { amount: MIN_WITHDRAWAL_AMOUNT }) });
    }

    if (!upiId) {
      return res.status(400).json({ success: false, message: req.t('validation.required_field') });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: req.t('general.not_found') });
    }

    if ((user.referralBalance || 0) < amount) {
      return res.status(400).json({ success: false, message: req.t('referral.insufficient_balance') });
    }

    // Create transaction
    const transaction = await Transaction.create({
      userId: user._id,
      type: 'withdrawal',
      amount: amount,
      upiId: upiId,
      description: `Withdrawal request to ${upiId}`,
      status: 'pending'
    });

    // Deduct from referral balance
    user.referralBalance -= amount;
    await user.save();

    // Notify all admins about the new withdrawal request
    try {
      const io = req.app.get('io');
      const admins = await User.find({ role: 'admin' }).select('_id');
      for (const admin of admins) {
        await createNotification({
          userId: admin._id,
          title: 'New Withdrawal Request',
          message: `${user.name} has requested a withdrawal of ₹${amount} via UPI: ${upiId}`,
          type: 'withdrawal_pending',
          relatedId: transaction._id,
          io
        });
      }
    } catch (notifyErr) {
      console.error('❌ Withdrawal admin notification failed:', notifyErr.message);
    }

    res.status(200).json({
      success: true,
      message: req.t('general.success'),
      transactionId: transaction._id
    });
  } catch (error) {
    console.error('Error requesting withdrawal:', error);
    res.status(500).json({ success: false, message: req.t('general.server_error') });
  }
};

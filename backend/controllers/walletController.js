const crypto = require('crypto');
const Wallet = require('../models/Wallet');
const WalletTransaction = require('../models/WalletTransaction');
const RazorpayTopupOrder = require('../models/RazorpayTopupOrder');
const Razorpay = require('razorpay');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'dummy_key_id',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'dummy_key_secret',
});

// @desc    Get recruiter wallet balance & aggregates
// @route   GET /api/wallet
// @access  Recruiter
exports.getWallet = async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ recruiterId: req.user.id });
    if (!wallet) {
      // Wallet should normally be created at registration, but fallback just in case
      wallet = await Wallet.create({ recruiterId: req.user.id, balance: 0 });
    }

    // Aggregate lifetime credits and debits
    const aggregates = await WalletTransaction.aggregate([
      { $match: { recruiterId: req.user._id, status: 'SUCCESS' } },
      { 
        $group: { 
          _id: '$type', 
          totalAmount: { $sum: '$amount' },
          lastTransactionDate: { $max: '$createdAt' }
        } 
      }
    ]);

    let totalCredited = 0;
    let totalDebited = 0;
    let lastTransactionAt = null;

    aggregates.forEach(agg => {
      if (agg._id === 'CREDIT') totalCredited = agg.totalAmount;
      if (agg._id === 'DEBIT') totalDebited = agg.totalAmount;
      if (!lastTransactionAt || agg.lastTransactionDate > lastTransactionAt) {
        lastTransactionAt = agg.lastTransactionDate;
      }
    });

    res.status(200).json({ 
      success: true, 
      data: { 
        wallet_id: wallet._id,
        balance_paise: wallet.balance,
        balance_rupees: wallet.balance / 100,
        total_credited_paise: totalCredited,
        total_credited_rupees: totalCredited / 100,
        total_debited_paise: totalDebited,
        total_debited_rupees: totalDebited / 100,
        last_transaction_at: lastTransactionAt
      } 
    });
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error') || 'Server Error', error: err.message });
  }
};

// @desc    Get recruiter transaction history
// @route   GET /api/wallet/history
// @access  Recruiter
exports.getTransactionHistory = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const startIndex = (page - 1) * limit;

    const query = { recruiterId: req.user.id };
    
    if (req.query.type) {
      query.type = req.query.type.toUpperCase();
    }
    
    if (req.query.startDate || req.query.endDate) {
      query.createdAt = {};
      if (req.query.startDate) query.createdAt.$gte = new Date(req.query.startDate);
      if (req.query.endDate) query.createdAt.$lte = new Date(req.query.endDate);
    }

    const total = await WalletTransaction.countDocuments(query);
    const transactions = await WalletTransaction.find(query)
      .sort({ createdAt: -1 })
      .skip(startIndex)
      .limit(limit);

    res.status(200).json({ 
      success: true, 
      count: transactions.length,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      data: transactions.map(tx => ({
        transaction_id: tx._id,
        type: tx.type,
        amount_paise: tx.amount,
        amount_rupees: tx.amount / 100,
        description: tx.description,
        source: tx.source,
        reference_id: tx.referenceId,
        balance_after_paise: tx.balanceAfter,
        balance_after_rupees: tx.balanceAfter / 100,
        status: tx.status,
        created_at: tx.createdAt
      }))
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server Error', error: err.message });
  }
};

// @desc    Initiate wallet top-up via Razorpay
// @route   POST /api/wallet/topup
// @access  Recruiter
exports.initiateTopup = async (req, res) => {
  try {
    const { amount } = req.body; // Amount in paise

    if (!amount || !Number.isInteger(amount)) {
      return res.status(400).json({ success: false, message: 'Invalid amount. Must be an integer in paise.' });
    }

    if (amount < 1000 || amount > 1000000) {
      return res.status(400).json({ success: false, message: 'Amount must be between ₹10 and ₹10000.' });
    }

    let wallet = await Wallet.findOne({ recruiterId: req.user.id });
    if (!wallet) {
      return res.status(404).json({ success: false, message: 'Wallet not found.' });
    }

    const orderOptions = {
      amount: amount,
      currency: "INR",
      receipt: `tp_${Date.now()}`
    };

    const order = await razorpay.orders.create(orderOptions);

    const topupOrder = await RazorpayTopupOrder.create({
      recruiterId: req.user.id,
      razorpayOrderId: order.id,
      amount: amount,
      status: 'CREATED'
    });

    res.status(200).json({
      success: true,
      topup_order_id: topupOrder._id,
      order_id: order.id,
      amount: amount,
      currency: "INR",
      razorpay_key_id: process.env.RAZORPAY_KEY_ID || 'dummy_key_id'
    });
  } catch (err) {
    console.error("Wallet Top-up Error:", err);
    res.status(500).json({ success: false, message: 'Failed to initiate top-up', error: err.message });
  }
};

// @desc    Verify wallet top-up via Razorpay frontend success
// @route   POST /api/wallet/verify-topup
// @access  Recruiter
exports.verifyTopup = async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    
    const secret = process.env.RAZORPAY_KEY_SECRET || 'dummy_key_secret';
    
    const generated_signature = crypto.createHmac('sha256', secret)
      .update(razorpay_order_id + "|" + razorpay_payment_id)
      .digest('hex');
      
    if (generated_signature !== razorpay_signature) {
       return res.status(400).json({ success: false, message: 'Invalid payment signature' });
    }
    
    const topupOrder = await RazorpayTopupOrder.findOne({ razorpayOrderId: razorpay_order_id });
    if (!topupOrder) {
        return res.status(404).json({ success: false, message: 'Topup order not found' });
    }
    
    const existingTx = await WalletTransaction.findOne({ idempotencyKey: razorpay_payment_id });
    if (existingTx) {
      return res.status(200).json({ success: true, message: 'Already processed' });
    }

    const session = await Wallet.startSession();
    session.startTransaction();
    try {
      const wallet = await Wallet.findOne({ recruiterId: topupOrder.recruiterId }).session(session);
      if (!wallet) throw new Error('Wallet not found');

      const currentBalance = wallet.balance;
      const amountPaise = topupOrder.amount;
      const newBalance = currentBalance + amountPaise;

      wallet.balance = newBalance;
      await wallet.save({ session });

      await WalletTransaction.create([{
        walletId: wallet._id,
        recruiterId: wallet.recruiterId,
        type: 'CREDIT',
        amount: amountPaise,
        balanceBefore: currentBalance,
        balanceAfter: newBalance,
        source: 'RAZORPAY_TOPUP',
        referenceId: razorpay_payment_id,
        idempotencyKey: razorpay_payment_id,
        status: 'SUCCESS',
        description: 'Wallet Top-up'
      }], { session });

      topupOrder.status = 'PAID';
      topupOrder.razorpayPaymentId = razorpay_payment_id;
      await topupOrder.save({ session });

      await session.commitTransaction();
      session.endSession();
      
      return res.status(200).json({ success: true, message: 'Topup verified and applied' });
    } catch (txError) {
      await session.abortTransaction();
      session.endSession();
      console.error('Wallet Top-up Verify Error:', txError);
      return res.status(500).json({ success: false, message: 'Database error processing topup' });
    }
  } catch (err) {
    console.error("Wallet Verify Error:", err);
    res.status(500).json({ success: false, message: 'Failed to verify top-up', error: err.message });
  }
};

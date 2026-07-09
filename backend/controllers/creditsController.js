const crypto = require('crypto');
const UserCredits = require('../models/UserCredits'); // model renamed to UserCredits internally
const CreditTransaction = require('../models/CreditTransaction'); // model renamed to CreditTransaction
const RazorpayTopupOrder = require('../models/RazorpayTopupOrder');
const Razorpay = require('razorpay');
const { CREDIT_PACKS, getPackById } = require('../models/CreditPacks');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'dummy_key_id',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'dummy_key_secret',
});

// @desc    Get available credit packs (no auth required)
// @route   GET /api/credits/packs
exports.getCreditPacks = async (req, res) => {
  res.status(200).json({
    success: true,
    data: CREDIT_PACKS.map(p => ({
      id: p.id,
      name: p.name,
      price_rupees: p.priceRupees,
      credits: p.credits,
      description: p.description
    }))
  });
};

// @desc    Get recruiter credit balance & aggregates
// @route   GET /api/credits
// @access  Recruiter
exports.getCredits = async (req, res) => {
  try {
    let userCredits = await UserCredits.findOne({ recruiterId: req.user.id });
    if (!userCredits) {
      // Create with 0 credits if not found (fallback — should be created at registration)
      userCredits = await UserCredits.create({ recruiterId: req.user.id, credits: 0 });
    }

    // Aggregate lifetime credits purchased and consumed
    const aggregates = await CreditTransaction.aggregate([
      { $match: { recruiterId: req.user._id, status: 'SUCCESS' } },
      {
        $group: {
          _id: '$type',
          totalCredits: { $sum: '$credits' },
          lastTransactionDate: { $max: '$createdAt' }
        }
      }
    ]);

    let totalCredited = 0;
    let totalDebited = 0;
    let lastTransactionAt = null;

    aggregates.forEach(agg => {
      if (agg._id === 'CREDIT') totalCredited = agg.totalCredits;
      if (agg._id === 'DEBIT') totalDebited = agg.totalCredits;
      if (!lastTransactionAt || agg.lastTransactionDate > lastTransactionAt) {
        lastTransactionAt = agg.lastTransactionDate;
      }
    });

    res.status(200).json({
      success: true,
      data: {
        credits_id: userCredits._id,
        credits_balance: userCredits.credits,
        total_credits_purchased: totalCredited,
        total_credits_used: totalDebited,
        last_transaction_at: lastTransactionAt,
        is_refundable: false,
        is_transferable: false
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error') || 'Server Error', error: err.message });
  }
};

// @desc    Get recruiter credit transaction history
// @route   GET /api/credits/history
// @access  Recruiter
exports.getCreditHistory = async (req, res) => {
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

    const total = await CreditTransaction.countDocuments(query);
    const transactions = await CreditTransaction.find(query)
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
        credits: tx.credits,
        pack_id: tx.packId,
        description: tx.description,
        source: tx.source,
        reference_id: tx.referenceId,
        credits_after: tx.creditsAfter,
        status: tx.status,
        created_at: tx.createdAt
      }))
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server Error', error: err.message });
  }
};

// @desc    Initiate credit pack purchase via Razorpay
// @route   POST /api/credits/purchase
// @access  Recruiter
exports.initiatePurchase = async (req, res) => {
  try {
    const { packId } = req.body;

    if (!packId) {
      return res.status(400).json({ success: false, message: 'A credit pack ID is required. Use GET /api/credits/packs to see available packs.' });
    }

    const pack = getPackById(packId);
    if (!pack) {
      return res.status(400).json({ success: false, message: `Invalid pack ID '${packId}'. Use GET /api/credits/packs to see available packs.` });
    }

    let userCredits = await UserCredits.findOne({ recruiterId: req.user.id });
    if (!userCredits) {
      return res.status(404).json({ success: false, message: 'Credit account not found.' });
    }

    const orderOptions = {
      amount: pack.pricePaise,
      currency: 'INR',
      receipt: `cp_${Date.now()}`
    };

    const order = await razorpay.orders.create(orderOptions);

    const packOrder = await RazorpayTopupOrder.create({
      recruiterId: req.user.id,
      razorpayOrderId: order.id,
      amount: pack.pricePaise,
      packId: pack.id,
      creditsToGrant: pack.credits,
      status: 'CREATED'
    });

    res.status(200).json({
      success: true,
      pack_order_id: packOrder._id,
      order_id: order.id,
      pack: {
        id: pack.id,
        name: pack.name,
        credits: pack.credits,
        price_rupees: pack.priceRupees
      },
      amount_paise: pack.pricePaise,
      currency: 'INR',
      razorpay_key_id: process.env.RAZORPAY_KEY_ID || 'dummy_key_id'
    });
  } catch (err) {
    console.error('Credit Pack Purchase Error:', err);
    res.status(500).json({ success: false, message: 'Failed to initiate credit pack purchase', error: err.message });
  }
};

// @desc    Verify credit pack purchase via Razorpay frontend success
// @route   POST /api/credits/verify-purchase
// @access  Recruiter
exports.verifyPurchase = async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    const secret = process.env.RAZORPAY_KEY_SECRET || 'dummy_key_secret';

    const generated_signature = crypto.createHmac('sha256', secret)
      .update(razorpay_order_id + '|' + razorpay_payment_id)
      .digest('hex');

    if (generated_signature !== razorpay_signature) {
      return res.status(400).json({ success: false, message: 'Invalid payment signature' });
    }

    const packOrder = await RazorpayTopupOrder.findOne({ razorpayOrderId: razorpay_order_id });
    if (!packOrder) {
      return res.status(404).json({ success: false, message: 'Credit pack order not found' });
    }

    const existingTx = await CreditTransaction.findOne({ idempotencyKey: razorpay_payment_id });
    if (existingTx) {
      return res.status(200).json({ success: true, message: 'Already processed' });
    }

    const session = await UserCredits.startSession();
    session.startTransaction();
    try {
      const userCredits = await UserCredits.findOne({ recruiterId: packOrder.recruiterId }).session(session);
      if (!userCredits) throw new Error('Credit account not found');

      const currentCredits = userCredits.credits;
      const creditsToAdd = packOrder.creditsToGrant;
      const newCredits = currentCredits + creditsToAdd;

      userCredits.credits = newCredits;
      await userCredits.save({ session });

      await CreditTransaction.create([{
        creditsId: userCredits._id,
        recruiterId: userCredits.recruiterId,
        type: 'CREDIT',
        credits: creditsToAdd,
        creditsBefore: currentCredits,
        creditsAfter: newCredits,
        source: 'CREDIT_PACK_PURCHASE',
        packId: packOrder.packId,
        referenceId: razorpay_payment_id,
        idempotencyKey: razorpay_payment_id,
        status: 'SUCCESS',
        description: `Credit Pack Purchase: ${packOrder.packId} (+${creditsToAdd} credits)`
      }], { session });

      packOrder.status = 'PAID';
      packOrder.razorpayPaymentId = razorpay_payment_id;
      await packOrder.save({ session });

      await session.commitTransaction();
      session.endSession();

      return res.status(200).json({
        success: true,
        message: 'Credit pack purchase verified',
        credits_added: creditsToAdd,
        new_balance: newCredits
      });
    } catch (txError) {
      await session.abortTransaction();
      session.endSession();
      console.error('Credit Pack Verify Error:', txError);
      return res.status(500).json({ success: false, message: 'Database error processing credit pack purchase' });
    }
  } catch (err) {
    console.error('Credit Verify Error:', err);
    res.status(500).json({ success: false, message: 'Failed to verify credit pack purchase', error: err.message });
  }
};

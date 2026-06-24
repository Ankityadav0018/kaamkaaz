const mongoose = require('mongoose');

const walletTransactionSchema = new mongoose.Schema({
  walletId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Wallet',
    required: true
  },
  recruiterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['CREDIT', 'DEBIT'],
    required: true
  },
  amount: {
    type: Number,
    required: true, // Store in paise
    min: 0,
    validate: { validator: Number.isInteger, message: '{VALUE} is not an integer value' }
  },
  balanceBefore: {
    type: Number,
    required: true,
    min: 0,
    validate: { validator: Number.isInteger, message: '{VALUE} is not an integer value' }
  },
  balanceAfter: {
    type: Number,
    required: true,
    min: 0,
    validate: { validator: Number.isInteger, message: '{VALUE} is not an integer value' }
  },
  source: {
    type: String,
    enum: ['RAZORPAY_TOPUP', 'URGENT_JOB_DEDUCTION', 'REFERRAL_BONUS', 'URGENT_JOB_REFUND'],
    required: true
  },
  referenceId: {
    type: String, // Razorpay Payment ID or Job Post ID
    default: null
  },
  idempotencyKey: {
    type: String,
    required: true,
    unique: true
  },
  status: {
    type: String,
    enum: ['PENDING', 'SUCCESS', 'FAILED'],
    default: 'SUCCESS'
  },
  description: {
    type: String,
    default: ''
  }
}, { timestamps: true });

module.exports = mongoose.model('WalletTransaction', walletTransactionSchema);

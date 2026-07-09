const mongoose = require('mongoose');

/**
 * CreditTransaction — records every credit movement (purchase or deduction).
 *
 * RBI PPI Compliance:
 *   - type 'CREDIT': credits added (from credit pack purchase or referral bonus)
 *   - type 'DEBIT': credits consumed (for job posting)
 *   - No 'WITHDRAWAL' or cash redemption type exists — intentionally omitted.
 */
const creditTransactionSchema = new mongoose.Schema({
  creditsId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'UserCredits',
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
  // Integer credit units (not paise)
  credits: {
    type: Number,
    required: true,
    min: 0,
    validate: { validator: Number.isInteger, message: '{VALUE} is not a valid integer credit count' }
  },
  creditsBefore: {
    type: Number,
    required: true,
    min: 0,
    validate: { validator: Number.isInteger, message: '{VALUE} is not a valid integer credit count' }
  },
  creditsAfter: {
    type: Number,
    required: true,
    min: 0,
    validate: { validator: Number.isInteger, message: '{VALUE} is not a valid integer credit count' }
  },
  source: {
    type: String,
    enum: [
      'CREDIT_PACK_PURCHASE', // Razorpay purchase of a defined credit pack
      'JOB_POST_DEDUCTION',   // Credits consumed for posting an urgent job
      'REFERRAL_BONUS',       // Credits from referral program
      'JOB_POST_REFUND'       // Credits refunded on job cancellation
    ],
    required: true
  },
  // ID of the credit pack purchased (e.g. 'pack_starter_100'). Null for non-purchase transactions.
  packId: {
    type: String,
    default: null
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

// Keep 'wallettransactions' collection for migration safety
module.exports = mongoose.model('CreditTransaction', creditTransactionSchema, 'wallettransactions');

const mongoose = require('mongoose');

const razorpayPackOrderSchema = new mongoose.Schema({
  recruiterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  razorpayOrderId: {
    type: String,
    required: true,
    unique: true
  },
  // Razorpay order amount in paise (for payment gateway)
  amount: {
    type: Number,
    required: true,
    min: 0,
    validate: { validator: Number.isInteger, message: '{VALUE} is not an integer value' }
  },
  // The credit pack that was purchased (e.g. 'pack_starter_100')
  packId: {
    type: String,
    required: true,
    default: 'pack_starter_100'
  },
  // Number of job posting credits to grant on successful payment
  creditsToGrant: {
    type: Number,
    required: true,
    min: 1,
    validate: { validator: Number.isInteger, message: '{VALUE} is not a valid integer credit count' }
  },
  status: {
    type: String,
    enum: ['CREATED', 'PAID', 'FAILED', 'EXPIRED'],
    default: 'CREATED'
  },
  razorpayPaymentId: {
    type: String,
    default: null
  },
  webhookReceivedAt: {
    type: Date,
    default: null
  }
}, { timestamps: true });

module.exports = mongoose.model('RazorpayTopupOrder', razorpayPackOrderSchema);

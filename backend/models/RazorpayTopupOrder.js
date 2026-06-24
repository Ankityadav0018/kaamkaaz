const mongoose = require('mongoose');

const razorpayTopupOrderSchema = new mongoose.Schema({
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
  amount: {
    type: Number,
    required: true,
    min: 0,
    validate: { validator: Number.isInteger, message: '{VALUE} is not an integer value' }
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

module.exports = mongoose.model('RazorpayTopupOrder', razorpayTopupOrderSchema);

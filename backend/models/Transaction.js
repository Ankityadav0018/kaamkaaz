const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['referral_reward', 'referral_bonus', 'withdrawal'],
    required: true
  },
  amount: {
    type: Number,
    required: true
  },
  description: {
    type: String,
    trim: true
  },
  upiId: {
    type: String,
    trim: true
  },
  status: {
    type: String,
    enum: ['pending', 'completed', 'failed', 'rejected'],
    default: 'completed'
  }
}, { timestamps: true });

transactionSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Transaction', transactionSchema);

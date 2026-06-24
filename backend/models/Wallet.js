const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema({
  recruiterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  balance: {
    type: Number,
    default: 0,
    min: 0, // Store in paise (100 paise = 1 INR)
    validate: {
      validator: Number.isInteger,
      message: '{VALUE} is not an integer value'
    }
  }
}, { timestamps: true });

module.exports = mongoose.model('Wallet', walletSchema);

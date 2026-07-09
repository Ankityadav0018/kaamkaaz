const mongoose = require('mongoose');

/**
 * UserCredits — stores a recruiter's current job posting credit balance.
 *
 * RBI PPI Compliance:
 *   - Credits are NON-TRANSFERABLE: tied to recruiterId only, no path to transfer between users.
 *   - Credits are NON-REFUNDABLE: no cashback or cash redemption endpoint exists.
 *   - Credits are CLOSED-LOOP: usable only for posting jobs on this platform.
 */
const userCreditsSchema = new mongoose.Schema({
  recruiterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  // Integer count of job posting credits available
  credits: {
    type: Number,
    default: 0,
    min: 0,
    validate: {
      validator: Number.isInteger,
      message: '{VALUE} is not a valid integer credit count'
    }
  },
  // Policy constants stored as schema-level metadata (non-modifiable via API)
  is_refundable: {
    type: Boolean,
    default: false,
    immutable: true  // Cannot be changed after creation
  },
  is_transferable: {
    type: Boolean,
    default: false,
    immutable: true  // Cannot be changed after creation
  }
}, { timestamps: true });

// Keep using the old 'wallets' collection for migration safety
// (Mongoose model name is 'UserCredits' but MongoDB collection stays 'wallets')
module.exports = mongoose.model('UserCredits', userCreditsSchema, 'wallets');

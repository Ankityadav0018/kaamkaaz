const mongoose = require('mongoose');

const skillBadgeSchema = new mongoose.Schema({
  workerId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true
  },
  skill: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'verified', 'rejected'],
    default: 'pending'
  },
  documentUrl: {
    type: String,
    default: ''
  },
  documentPublicId: {
    type: String,
    default: ''
  },
  adminNote: {
    type: String,
    default: ''
  },
  verifiedAt: {
    type: Date
  }
}, { timestamps: true });

// Prevent duplicate pending/verified requests for the same skill by the same worker
skillBadgeSchema.index({ workerId: 1, skill: 1 }, { unique: true });

module.exports = mongoose.model('SkillBadge', skillBadgeSchema);

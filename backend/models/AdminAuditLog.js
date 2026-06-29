const mongoose = require('mongoose');

/**
 * AdminAuditLog — Layer 4
 * Persists every admin API call with intent, IP, and success status.
 * Also tracks co-approval for destructive routes.
 */
const adminAuditLogSchema = new mongoose.Schema({
  adminId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  coApproverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  intent: {
    type: String,
    required: true,
    trim: true,
    maxlength: 500
  },
  method: {
    type: String,
    enum: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    required: true
  },
  route: {
    type: String,
    required: true
  },
  ip: {
    type: String,
    required: true
  },
  success: {
    type: Boolean,
    required: true
  },
  failReason: {
    type: String,
    default: null
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  }
}, { timestamps: false });

// Auto-delete logs older than 1 year
adminAuditLogSchema.index({ timestamp: 1 }, { expireAfterSeconds: 365 * 24 * 60 * 60 });

module.exports = mongoose.model('AdminAuditLog', adminAuditLogSchema);

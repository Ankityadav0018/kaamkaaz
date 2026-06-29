const mongoose = require('mongoose');

/**
 * RecruiterAuditLog — Section 4
 * Logs every recruiter action that touches worker personal data:
 * profile views, contact reveals, bulk exports, etc.
 */
const recruiterAuditLogSchema = new mongoose.Schema({
  recruiterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  action: {
    type: String,
    required: true,
    // e.g. 'view_worker_profile', 'view_contact', 'view_applications', 'export_data'
    trim: true
  },
  targetWorkerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
    index: true
  },
  relatedJobId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Job',
    default: null
  },
  ip: {
    type: String,
    default: ''
  },
  meta: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  timestamp: {
    type: Date,
    default: Date.now
    // index removed — the TTL schema.index() below already creates {timestamp:1}
  }
}, { timestamps: false });

// Auto-delete logs older than 6 months
recruiterAuditLogSchema.index(
  { timestamp: 1 },
  { expireAfterSeconds: 6 * 30 * 24 * 60 * 60 }
);

module.exports = mongoose.model('RecruiterAuditLog', recruiterAuditLogSchema);

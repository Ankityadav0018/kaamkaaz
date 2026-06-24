const mongoose = require('mongoose');

const disputeSchema = new mongoose.Schema({
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
  raisedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  raisedByRole: {
    type: String,
    enum: ['worker', 'recruiter'],
    required: true
  },
  againstUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  category: {
    type: String,
    enum: [
      'payment_not_received',
      'worker_no_show',
      'wrong_job_description',
      'work_quality_issue',
      'unsafe_conditions',
      'other'
    ],
    required: true
  },
  description: { type: String, required: true, maxlength: 500 },
  status: {
    type: String,
    enum: ['open', 'under_review', 'resolved', 'dismissed'],
    default: 'open'
  },
  adminNote: { type: String, default: null },
  resolvedAt: { type: Date, default: null },
  resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }
}, { timestamps: true });

module.exports = mongoose.model('Dispute', disputeSchema);

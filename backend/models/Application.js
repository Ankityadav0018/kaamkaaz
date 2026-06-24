const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema({
  jobId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Job',
    required: true
  },
  workerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  message: { type: String, default: '', maxlength: 500 },
  preferredWage: { type: Number, default: null },
  status: {
    type: String,
    enum: ['applied', 'accepted', 'rejected', 'withdrawn', 'completed'],
    default: 'applied'
  },
  respondedAt: { type: Date, default: null },
  // Ratings
  workerRating: {
    score: { type: Number, min: 1, max: 5 },
    review: { type: String, default: '' },
    createdAt: { type: Date }
  },
  recruiterRating: {
    score: { type: Number, min: 1, max: 5 },
    review: { type: String, default: '' },
    createdAt: { type: Date }
  },
  // After acceptance - contact is revealed
  contactRevealed: { type: Boolean, default: false }
}, { timestamps: true });

// One application per job per worker
applicationSchema.index({ jobId: 1, workerId: 1 }, { unique: true });

module.exports = mongoose.model('Application', applicationSchema);

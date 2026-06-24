const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false
  },
  jobId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Job',
    required: false
  },
  reportedUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false
  },
  jobTitle: String,
  workerName: String,
  recruiterName: String,
  reason: String,
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  screenshot: {
    type: String // Cloudinary URL
  },
  status: {
    type: String,
    enum: ['pending', 'investigating', 'resolved', 'closed'],
    default: 'pending'
  },
  adminNote: String
}, { timestamps: true });

module.exports = mongoose.model('Report', reportSchema);

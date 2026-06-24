const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  message: { type: String, required: true },
  type: {
    type: String,
    enum: [
      'job_posted', 'job_application', 'application_accepted', 'application_rejected', 
      'kyc_approved', 'kyc_rejected', 'recruiter_verified', 'recruiter_suspended', 
      'rating_received', 'chat', 'message', 'general',
      'referral_success', 'recruiter_pending', 'invitation', 'recruiter_onboarding_pending',
      'driver_kyc_pending', 'withdrawal_pending', 'kyc_update'
    ],
    default: 'general'
  },
  relatedId: { type: mongoose.Schema.Types.ObjectId, default: null },
  isRead: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);

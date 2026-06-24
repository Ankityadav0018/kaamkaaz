const cloudinary = require('cloudinary').v2;
const KycRecord = require('../models/KycRecord');
const User = require('../models/User');
const { kycQueue } = require('../queues');

// @desc    Get Cloudinary signed URL for secure direct upload
// @route   POST /api/kyc/upload-url
// @access  Private
exports.getUploadUrl = async (req, res) => {
  try {
    const { folder = 'kyc_documents' } = req.body;
    const timestamp = Math.round(new Date().getTime() / 1000);
    
    const paramsToSign = {
      timestamp,
      folder: `kaamkaaz/${folder}`,
      transformation: 'q_auto,f_auto'
    };

    const signature = cloudinary.utils.api_sign_request(
      paramsToSign,
      process.env.CLOUDINARY_API_SECRET
    );

    res.status(200).json({
      success: true,
      data: {
        signature,
        timestamp,
        cloudName: process.env.CLOUDINARY_CLOUD_NAME,
        apiKey: process.env.CLOUDINARY_API_KEY,
        folder: paramsToSign.folder,
        uploadUrl: `https://api.cloudinary.com/v1_1/${process.env.CLOUDINARY_CLOUD_NAME}/image/upload`
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Submit KYC documents
// @route   POST /api/kyc/submit
// @access  Private
exports.submitKyc = async (req, res) => {
  try {
    const { aadhaarNumber, panNumber, frontImageUrl, backImageUrl, panImageUrl } = req.body;
    
    let kycRecord = await KycRecord.findOne({ userId: req.user.id });
    if (!kycRecord) {
      kycRecord = new KycRecord({ userId: req.user.id });
    }

    if (aadhaarNumber) kycRecord.documentNumber = aadhaarNumber;
    if (frontImageUrl) kycRecord.frontImageUrl = frontImageUrl;
    if (backImageUrl) kycRecord.backImageUrl = backImageUrl;
    if (panImageUrl) kycRecord.panImageUrl = panImageUrl;
    
    kycRecord.verificationState = 'pending';
    kycRecord.submittedAt = new Date();
    await kycRecord.save();

    // Update User model
    const user = await User.findByIdAndUpdate(req.user.id, { kycStatus: 'pending' }, { new: true });

    // Notify Admin
    const { notifyAdmins } = require('../utils/notification');
    await notifyAdmins({
      title: '📋 New KYC Submission',
      message: `${user.name} has submitted documents for verification.`,
      type: 'kyc_pending',
      relatedId: user._id,
      io: req.app.get('io')
    });

    // Enqueue background job for async processing with retries
    await kycQueue.add('process_submission', { 
      userId: req.user.id,
      type: 'process_submission'
    }, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 2000 }
    });

    res.status(200).json({ success: true, message: 'KYC Submitted successfully', data: kycRecord });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Admin reviews KYC
// @route   PATCH /api/kyc/review/:userId
// @access  Private (Admin)
exports.reviewKyc = async (req, res) => {
  try {
    const { status, reason } = req.body; // 'approved' or 'rejected'
    const userId = req.params.userId;

    const kycRecord = await KycRecord.findOne({ userId });
    const user = await User.findById(userId);

    if (!kycRecord || !user) {
      return res.status(404).json({ success: false, message: 'User or KYC record not found' });
    }

    kycRecord.verificationState = status;
    kycRecord.rejectionReason = status === 'rejected' ? reason : '';
    if (status === 'approved') kycRecord.verifiedAt = new Date();
    await kycRecord.save();

    user.kycStatus = status;
    user.kycNote = kycRecord.rejectionReason;
    await user.save();

    // Notify User
    const { createNotification } = require('../utils/notification');
    await createNotification({
      userId: user._id,
      title: status === 'approved' ? '✅ KYC Approved!' : '❌ KYC Rejected',
      message: status === 'approved' ? 'You can now apply for jobs.' : `Reason: ${reason || 'Invalid documents.'}`,
      type: status === 'approved' ? 'kyc_approved' : 'kyc_rejected',
      io: req.app.get('io')
    });

    res.status(200).json({ success: true, message: `KYC ${status}` });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

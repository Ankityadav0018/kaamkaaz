const { generateSignature } = require('../utils/cloudinaryHelper');

/**
 * @desc    Get a signed Cloudinary upload signature
 * @route   GET /api/upload/signature
 * @access  Private
 */
exports.getUploadSignature = async (req, res) => {
  try {
    const { type } = req.query;
    
    // Security: Only allow specific folders/types to prevent arbitrary bucket usage
    const allowedTypes = ['kyc', 'profile', 'job_proof', 'job_site', 'driver_docs', 'portfolio', 'skill_badge', 'chat_audio', 'chat_media', 'chat_image', 'other'];
    if (!type || !allowedTypes.includes(type)) {
      return res.status(400).json({ success: false, message: 'Invalid upload type requested' });
    }

    // Organize by user ID for privacy and easy cleanup, or 'anonymous' if not logged in
    const userId = req.user ? req.user.id : 'anonymous';
    const userFolder = `user_${userId}/${type}`;
    
    // Generate a unique public ID (filename) on backend to prevent collisions/tampering
    const uniqueId = `${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    
    const signatureData = generateSignature(userFolder, uniqueId);

    res.status(200).json({
      success: true,
      data: signatureData
    });
  } catch (err) {
    console.error('Signature Generation Error:', err.message);
    res.status(500).json({ success: false, message: req.t('upload.upload_failed') });
  }
};

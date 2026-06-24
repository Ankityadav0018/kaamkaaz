const User = require('../models/User');
const { createNotification } = require('../utils/notification');
const { deleteImage } = require('../utils/cloudinaryHelper');

// ─── Get Driver Profile ───────────────────────────────────────────────────────
// GET /api/driver/profile
exports.getDriverProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('driverProfile workerType');
    if (!user) return res.status(404).json({ success: false, message: req.t('general.not_found') });
    res.status(200).json({ success: true, data: user.driverProfile || {} });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── Save / Update Driver Profile ────────────────────────────────────────────
// POST /api/driver/profile
exports.saveDriverProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    const {
      vehicleTypes, experienceYears, languages,
      willingToOutstation, hasOwnVehicle, ownVehicleType,
      ownVehicleRegNumber, 
      // Cloudinary pre-uploaded info
      licenceFrontUrl, licenceFrontPublicId,
      licenceBackUrl, licenceBackPublicId,
      aadhaarUrl, aadhaarPublicId,
      rcBookUrl, rcBookPublicId,
      policeVerificationUrl, policeVerificationPublicId,
      passportPhotoUrl, passportPhotoPublicId
    } = req.body;

    // Validate mandatory docs
    if (!licenceFrontUrl || !licenceBackUrl || !aadhaarUrl || !passportPhotoUrl) {
      return res.status(400).json({
        success: false,
        message: 'Licence front, licence back, Aadhaar, and passport photo are mandatory'
      });
    }

    const dp = user.driverProfile || {};

    // Secure helper to update and cleanup
    const updateDoc = async (newUrl, newId, fieldUrl, fieldId) => {
      if (newUrl && newId) {
        if (dp[fieldId]) await deleteImage(dp[fieldId]);
        dp[fieldUrl] = newUrl;
        dp[fieldId] = newId;
      }
    };

    await updateDoc(licenceFrontUrl, licenceFrontPublicId, 'licenceFrontUrl', 'licenceFrontPublicId');
    await updateDoc(licenceBackUrl, licenceBackPublicId, 'licenceBackUrl', 'licenceBackPublicId');
    await updateDoc(aadhaarUrl, aadhaarPublicId, 'aadhaarUrl', 'aadhaarPublicId');
    await updateDoc(rcBookUrl, rcBookPublicId, 'rcBookUrl', 'rcBookPublicId');
    await updateDoc(policeVerificationUrl, policeVerificationPublicId, 'policeVerificationUrl', 'policeVerificationPublicId');
    await updateDoc(passportPhotoUrl, passportPhotoPublicId, 'passportPhotoUrl', 'passportPhotoPublicId');

    const updatedUser = await User.findByIdAndUpdate(
      req.user.id,
      {
        workerType: 'driver',
        'driverProfile.vehicleTypes': vehicleTypes || [],
        'driverProfile.experienceYears': parseInt(experienceYears) || 0,
        'driverProfile.languages': languages || [],
        'driverProfile.willingToOutstation': willingToOutstation === true || willingToOutstation === 'true',
        'driverProfile.hasOwnVehicle': hasOwnVehicle === true || hasOwnVehicle === 'true',
        'driverProfile.ownVehicleType': ownVehicleType || '',
        'driverProfile.ownVehicleRegNumber': ownVehicleRegNumber || '',
        'driverProfile.licenceFrontUrl': dp.licenceFrontUrl,
        'driverProfile.licenceFrontPublicId': dp.licenceFrontPublicId,
        'driverProfile.licenceBackUrl': dp.licenceBackUrl,
        'driverProfile.licenceBackPublicId': dp.licenceBackPublicId,
        'driverProfile.aadhaarUrl': dp.aadhaarUrl,
        'driverProfile.aadhaarPublicId': dp.aadhaarPublicId,
        'driverProfile.rcBookUrl': dp.rcBookUrl,
        'driverProfile.rcBookPublicId': dp.rcBookPublicId,
        'driverProfile.policeVerificationUrl': dp.policeVerificationUrl,
        'driverProfile.policeVerificationPublicId': dp.policeVerificationPublicId,
        'driverProfile.passportPhotoUrl': dp.passportPhotoUrl,
        'driverProfile.passportPhotoPublicId': dp.passportPhotoPublicId,
        'driverProfile.kycStatus': 'pending',
        'driverProfile.kycSubmittedAt': new Date(),
      },
      { new: true, runValidators: false }
    ).select('-password');

    // Notify Admin of pending driver KYC request
    try {
      const { notifyAdmins } = require('../utils/notification');
      await notifyAdmins({
        title: '🚗 New Driver KYC Submission',
        message: `${user.name} has submitted driver documents for verification.`,
        type: 'driver_kyc_pending',
        relatedId: user._id,
        io: req.app.get('io')
      });
    } catch (notifyErr) {
      console.error('❌ Driver KYC admin notification failed:', notifyErr.message);
    }

    res.status(200).json({
      success: true,
      message: 'Driver profile submitted for verification',
      data: updatedUser
    });
  } catch (err) {
    console.error('Save Driver Profile Error:', err.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// ─── Get Nearby Verified Drivers (Recruiter) ─────────────────────────────────
// GET /api/driver/nearby
exports.getNearbyDrivers = async (req, res) => {
  try {
    const { lat, lng, radius = 50, vehicleType, outstation, page = 1, limit = 20 } = req.query;

    let query = {
      role: 'worker',
      workerType: 'driver',
      isBlocked: false,
      'driverProfile.kycStatus': 'verified',
    };

    if (vehicleType) {
      query['driverProfile.vehicleTypes'] = { $in: [vehicleType] };
    }
    if (outstation === 'true') {
      query['driverProfile.willingToOutstation'] = true;
    }

    let drivers;
    if (lat && lng) {
      const radiusInMeters = parseFloat(radius) * 1000;
      drivers = await User.find({
        ...query,
        location: {
          $near: {
            $geometry: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] },
            $maxDistance: radiusInMeters
          }
        }
      })
        .select('name rating completedJobsCount village location driverProfile profileImage')
        .skip((parseInt(page) - 1) * parseInt(limit))
        .limit(parseInt(limit));

      drivers = drivers.map(d => {
        const R = 6371;
        const dLat = (d.location.coordinates[1] - parseFloat(lat)) * Math.PI / 180;
        const dLon = (d.location.coordinates[0] - parseFloat(lng)) * Math.PI / 180;
        const a = Math.sin(dLat / 2) ** 2 + Math.cos(parseFloat(lat) * Math.PI / 180) *
          Math.cos(d.location.coordinates[1] * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
        const distKm = parseFloat((R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))).toFixed(1));
        return { ...d.toObject(), distance: distKm };
      });
    } else {
      drivers = await User.find(query)
        .select('name rating completedJobsCount village location driverProfile profileImage')
        .sort({ completedJobsCount: -1 })
        .skip((parseInt(page) - 1) * parseInt(limit))
        .limit(parseInt(limit));
    }

    res.status(200).json({ success: true, count: drivers.length, data: drivers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── Get Single Driver Profile (Public, Recruiter view) ──────────────────────
// GET /api/driver/:driverId
exports.getPublicDriverProfile = async (req, res) => {
  try {
    const driver = await User.findOne({
      _id: req.params.driverId,
      role: 'worker',
      workerType: 'driver',
      'driverProfile.kycStatus': 'verified',
    }).select('name rating completedJobsCount village driverProfile profileImage createdAt');

    if (!driver) {
      return res.status(404).json({ success: false, message: 'Driver not found or not verified' });
    }

    // Never expose phone to recruiter until formal acceptance
    const driverObj = driver.toObject();
    delete driverObj.phone;

    res.status(200).json({ success: true, data: driverObj });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── Admin: Get Pending Driver KYC Queue ─────────────────────────────────────
// GET /api/admin/driver-kyc
exports.adminGetPendingDrivers = async (req, res) => {
  try {
    const drivers = await User.find({
      role: 'worker',
      workerType: 'driver',
      'driverProfile.kycStatus': 'pending',
    }).select('name phone driverProfile createdAt');

    res.status(200).json({ success: true, count: drivers.length, data: drivers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── Admin: Approve or Reject Driver KYC ────────────────────────────────────
// PATCH /api/admin/driver-kyc/:userId
exports.adminReviewDriverKyc = async (req, res) => {
  try {
    const { status, reason } = req.body;
    if (!['verified', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Status must be verified or rejected' });
    }

    const update = {
      'driverProfile.kycStatus': status,
    };
    if (status === 'verified') {
      update['driverProfile.kycVerifiedAt'] = new Date();
      update['kycStatus'] = 'approved'; // Also unlock general KYC gate
    }
    if (status === 'rejected') {
      update['driverProfile.kycRejectionReason'] = reason || 'Documents unclear';
    }

    const driver = await User.findByIdAndUpdate(req.params.userId, update, { new: true });
    if (!driver) return res.status(404).json({ success: false, message: 'Driver not found' });

    // Send push notification
    const io = req.app.get('io');
    const notifMsg = status === 'verified'
      ? 'Your driving documents are verified! 🎉 You can now be hired as a driver.'
      : `Your driver KYC was rejected. Reason: ${reason || 'Documents unclear'}. Please re-upload.`;
    await createNotification({
      userId: driver._id,
      title: status === 'verified' ? '✅ Driver KYC Verified!' : '❌ Driver KYC Rejected',
      message: notifMsg,
      type: 'kyc_update',
      relatedId: driver._id,
      io
    });

    res.status(200).json({
      success: true,
      message: `Driver KYC ${status}`,
      data: driver
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

const User = require('../models/User');
const jwt = require('jsonwebtoken');
// Firebase removed
const supabase = require('../config/supabase');
const { createNotification, notifyAdmins } = require('../utils/notification');
const { generateReferralCode, applyReferralReward } = require('../utils/referralHelper');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const UserCredits = require('../models/UserCredits'); // UserCredits model




// @desc    Register user
// @route   POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { name, phone, email, password, role, skills, village, companyName, businessArea, language, workerType, aadhaarNumber, referralCode: incomingReferralCode } = req.body;

    if (!name || !phone || !password || !aadhaarNumber || !email) {
      return res.status(400).json({ success: false, message: req.t('validation.required_field') });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ success: false, message: 'Please provide a valid email address' });
    }

    const existing = await User.findOne({ phone });
    if (existing) {
      return res.status(400).json({ success: false, message: req.t('auth.phone_registered') });
    }

    const existingEmail = await User.findOne({ email: email.toLowerCase() });
    if (existingEmail) {
      return res.status(400).json({ success: false, message: 'This email is already registered' });
    }

    const existingAadhaar = await User.findOne({ aadhaarNumber });
    if (existingAadhaar) {
      return res.status(400).json({ success: false, message: req.t('auth.aadhaar_registered') });
    }

    const userData = {
      name, phone, email: email.toLowerCase(), password, aadhaarNumber,
      role: role || 'worker',
      language: language || 'hi',
      isPhoneVerified: true
    };

    if (role === 'worker') {
      userData.skills = skills || [];
      userData.village = village || '';
      userData.workerType = workerType || 'general';
    } else if (role === 'recruiter') {
      userData.companyName = companyName || '';
      userData.businessArea = businessArea || '';
    }

    const session = await mongoose.startSession();
    session.startTransaction();
    let user;
    try {
      const usersCreated = await User.create([userData], { session });
      user = usersCreated[0];

      if (user.role === 'recruiter') {
        await UserCredits.create([{ recruiterId: user._id, credits: 0 }], { session });
      }

      await session.commitTransaction();
      session.endSession();
    } catch (txError) {
      await session.abortTransaction();
      session.endSession();
      throw txError;
    }

    // Sync to Supabase for Auth functionality
    try {
      const { data, error } = await supabase.auth.admin.createUser({
        email: user.email,
        password: password,
        email_confirm: true,
        user_metadata: { name: user.name }
      });
      if (error) throw error;
      if (data && data.user) {
        user.supabaseUid = data.user.id;
        await user.save();
      }
    } catch (sbErr) {
      console.error('Supabase user creation failed (email might be in use):', sbErr.message);
    }

    // Generate Referral Code
    try {
      user.referralCode = await generateReferralCode(user.name, user.phone);
      await user.save();

      if (incomingReferralCode) {
        const referrer = await User.findOne({ referralCode: new RegExp(`^${incomingReferralCode.trim()}$`, 'i') });
        if (referrer && referrer._id.toString() !== user._id.toString()) {
          const applied = await applyReferralReward(referrer._id, user._id, req.app.get('io'));
          if (applied) {
            await createNotification({
              userId: referrer._id,
              title: '🎉 Referral Reward!',
              message: `${name} joined using your referral! ₹10 credited to your wallet.`,
              type: 'referral_success'
            });
          }
        }
      }
    } catch (refErr) {
      console.error('Referral Error:', refErr.message);
    }

    if (role === 'recruiter') {
      const io = req.app.get('io');
      await notifyAdmins({
        title: '🏗️ New Recruiter Registration',
        message: `${name} has registered as a recruiter and is pending verification.`,
        type: 'recruiter_pending',
        relatedId: user._id,
        io
      });
    }

    const token = user.getSignedJwtToken();
    res.status(201).json({
      success: true,
      message: req.t('general.success'),
      data: {
        token,
        user: _formatUser(user)
      }
    });
  } catch (err) {
    console.error('Register Error:', err.message);

    // Handle MongoDB unique constraint violations
    if (err.code === 11000 && err.keyValue) {
      const field = Object.keys(err.keyValue)[0];
      const value = err.keyValue[field];
      let friendlyField = field;

      if (field === 'phone') friendlyField = 'Phone number';
      else if (field === 'email') friendlyField = 'Email address';
      else if (field === 'aadhaarNumber' || field === 'recruiterVerification.aadhaarNumber') friendlyField = 'Aadhaar card number';
      else if (field === 'referralCode') friendlyField = 'Referral code';

      return res.status(400).json({
        success: false,
        message: `${friendlyField} '${value}' is already registered.`
      });
    }

    res.status(500).json({ success: false, message: 'Server error during registration: ' + err.message });
  }
};

// @desc    Login with password (phone OR email)
// @route   POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { phone, email, password, rememberMe = false } = req.body;
    if ((!phone && !email) || !password) {
      return res.status(400).json({ success: false, message: req.t('validation.required_field') });
    }

    let user;
    if (phone) {
      const cleanPhone = phone.toString().replace('+91', '').replace(/\s/g, '').trim();
      user = await User.findOne({ phone: cleanPhone }).select('+password');
    } else {
      user = await User.findOne({ email: email.toLowerCase() }).select('+password');
    }

    if (!user) {
      const field = phone ? 'Phone number' : 'Email address';
      return res.status(401).json({ success: false, message: `${field} is not registered` });
    }

    if (user.isBlocked) return res.status(403).json({ success: false, message: req.t('auth.account_blocked') });

    const isMatch = await user.matchPassword(password);
    if (!isMatch) return res.status(401).json({ success: false, message: req.t('auth.unauthorized') });

    // Token expiry: 30 days if Remember Me, 1 day for session-only
    const expiry = rememberMe ? '30d' : '1d';
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: expiry }
    );

    res.status(200).json({
      success: true,
      message: req.t('auth.login_success'),
      data: { token, rememberMe: !!rememberMe, user: _formatUser(user) }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error'), error: err.message });
  }
};

// @desc    Check if phone exists
// @route   POST /api/auth/check-phone
exports.checkPhone = async (req, res) => {
  try {
    const { phone } = req.body;
    const cleanPhone = phone.toString().replace('+91', '').replace(/\s/g, '').trim();
    const user = await User.findOne({ phone: cleanPhone });
    res.json({ exists: !!user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Check if email exists
// @route   POST /api/auth/check-email
exports.checkEmail = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ exists: false });
    const cleanEmail = email.toString().toLowerCase().trim();
    const user = await User.findOne({ email: cleanEmail });
    res.json({ exists: !!user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Supabase Verify (Unified Login/Register)
// @route   POST /api/auth/supabase-verify
exports.supabaseVerify = async (req, res) => {
  try {
    const { idToken, role, name, referralCode } = req.body;
    const { data: { user: supabaseUser }, error } = await supabase.auth.getUser(idToken);

    if (error || !supabaseUser) {
      return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
    }

    let user;
    if (supabaseUser.email) {
      user = await User.findOne({ email: supabaseUser.email.toLowerCase() });
    } else if (supabaseUser.phone) {
      const phone = supabaseUser.phone.replace('+91', '');
      user = await User.findOne({ phone });
    }

    if (!user) {
      if (!role) {
        return res.status(400).json({
          success: false,
          message: 'Role required for new users or account not found.'
        });
      }

      const phone = supabaseUser.phone ? supabaseUser.phone.replace('+91', '') : '';
      const email = supabaseUser.email ? supabaseUser.email.toLowerCase() : '';

      const session = await mongoose.startSession();
      session.startTransaction();
      try {
        const usersCreated = await User.create([{
          phone,
          email,
          name: name || '',
          role,
          supabaseUid: supabaseUser.id,
          referralCode: await generateReferralCode(name || 'usr', Date.now().toString()),
        }], { session });
        user = usersCreated[0];

        if (user.role === 'recruiter') {
          await UserCredits.create([{ recruiterId: user._id, balance: 0 }], { session });
        }
        await session.commitTransaction();
        session.endSession();
      } catch (txError) {
        await session.abortTransaction();
        session.endSession();
        throw txError;
      }

      if (referralCode) {
        const referrer = await User.findOne({ referralCode });
        if (referrer) {
          user.referredBy = referrer._id;
          await user.save();
          await applyReferralReward(referrer._id, user._id, req.app.get('io'));
          await createNotification({
            userId: referrer._id,
            title: '🎉 Referral Reward!',
            message: `${name || 'Someone'} joined using your referral! ₹5 credited to your wallet.`,
            type: 'referral_success'
          });
        }
      }
    } else {
      if (!user.supabaseUid) {
        user.supabaseUid = supabaseUser.id;
        await user.save();
      }
    }

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: _formatUser(user)
    });
  } catch (error) {
    console.error('Supabase Verify Error:', error.message);
    res.status(500).json({
      success: false,
      message: req.t('auth.unauthorized')
    });
  }
};

// @desc    Get current user
// @route   GET /api/auth/me
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    res.status(200).json({ success: true, data: _formatUser(user) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

const { deleteImage } = require('../utils/cloudinaryHelper');

// @desc    Update KYC documents
// @route   PUT /api/auth/kyc
exports.updateKyc = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    const {
      experienceYears,
      aadhaarNumber,
      // Now receiving pre-uploaded Cloudinary info for security/scalability
      aadhaarImage, aadhaarImagePublicId,
      aadhaarBackImage, aadhaarBackImagePublicId,
      livePhotoUrl, livePhotoPublicId,
      licenceFrontUrl, licenceFrontPublicId,
      licenceBackUrl, licenceBackPublicId
    } = req.body;

    const fields = {
      kycStatus: 'pending'
    };

    if (aadhaarNumber) fields.aadhaarNumber = aadhaarNumber;
    if (experienceYears) fields.experienceYears = parseInt(experienceYears);

    // Helper to update and cleanup old Cloudinary images
    const updateImageField = async (newUrl, newId, currentUrlField, currentIdField) => {
      if (newUrl && newId) {
        // If there's an old image, delete it from Cloudinary
        if (user[currentIdField]) {
          await deleteImage(user[currentIdField]);
        }
        fields[currentUrlField] = newUrl;
        fields[currentIdField] = newId;
      }
    };

    await updateImageField(aadhaarImage, aadhaarImagePublicId, 'aadhaarImage', 'aadhaarImagePublicId');
    await updateImageField(aadhaarBackImage, aadhaarBackImagePublicId, 'aadhaarBackImage', 'aadhaarBackImagePublicId');

    if (livePhotoUrl && livePhotoPublicId) {
      if (user.livePhotoPublicId) await deleteImage(user.livePhotoPublicId);
      fields.livePhotoUrl = livePhotoUrl;
      fields.livePhotoPublicId = livePhotoPublicId;
      fields.profileImage = livePhotoUrl;
      fields.profileImagePublicId = livePhotoPublicId;
    }

    // Driver specific
    if (user.workerType === 'driver') {
      const dp = user.driverProfile || {};

      if (licenceFrontUrl && licenceFrontPublicId) {
        if (dp.licenceFrontPublicId) await deleteImage(dp.licenceFrontPublicId);
        dp.licenceFrontUrl = licenceFrontUrl;
        dp.licenceFrontPublicId = licenceFrontPublicId;
      }
      if (licenceBackUrl && licenceBackPublicId) {
        if (dp.licenceBackPublicId) await deleteImage(dp.licenceBackPublicId);
        dp.licenceBackUrl = licenceBackUrl;
        dp.licenceBackPublicId = licenceBackPublicId;
      }

      if (fields.aadhaarImage) {
        dp.aadhaarUrl = fields.aadhaarImage;
        dp.aadhaarPublicId = fields.aadhaarImagePublicId;
      }
      if (fields.livePhotoUrl) {
        dp.passportPhotoUrl = fields.livePhotoUrl;
        dp.passportPhotoPublicId = fields.livePhotoPublicId;
      }
      if (fields.experienceYears) dp.experienceYears = fields.experienceYears;

      dp.kycStatus = 'pending';
      dp.kycSubmittedAt = new Date();
      fields.driverProfile = dp;
    }

    const updatedUser = await User.findByIdAndUpdate(req.user.id, fields, { new: true });

    // Notify Admin
    const io = req.app.get('io');
    await notifyAdmins({
      title: '📋 New KYC Submission',
      message: `${user.name} has submitted documents for verification.`,
      type: 'kyc_pending',
      relatedId: user._id,
      io
    });

    res.status(200).json({
      success: true,
      message: req.t('upload.upload_success'),
      data: _formatUser(updatedUser)
    });
  } catch (err) {
    console.error('Update KYC Error:', err.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// @desc    Update profile
// @route   PUT /api/auth/profile
exports.updateProfile = async (req, res) => {
  try {
    const {
      name, skills, village, companyName, businessArea, language, location,
      profileImage, aadhaarNumber, aadhaarImage, aadhaarBackImage,
      livePhotoUrl, skillProofImage, experienceYears, workerType, driverProfile
    } = req.body;
    const fields = {};

    if (name) fields.name = name;
    if (skills) fields.skills = skills;
    if (village !== undefined) fields.village = village;
    if (companyName !== undefined) fields.companyName = companyName;
    if (businessArea !== undefined) fields.businessArea = businessArea;
    if (language) fields.language = language;
    if (location) fields.location = location;
    if (profileImage) fields.profileImage = profileImage;
    if (aadhaarNumber) fields.aadhaarNumber = aadhaarNumber;
    if (aadhaarImage) fields.aadhaarImage = aadhaarImage;
    if (aadhaarBackImage) fields.aadhaarBackImage = aadhaarBackImage;
    if (livePhotoUrl) {
      fields.livePhotoUrl = livePhotoUrl;
      // Also update profile image when live photo is provided
      fields.profileImage = livePhotoUrl;
    }
    if (skillProofImage) fields.skillProofImage = skillProofImage;
    if (experienceYears !== undefined) fields.experienceYears = experienceYears;
    if (workerType) fields.workerType = workerType;
    if (driverProfile) fields.driverProfile = driverProfile;

    // If docs are provided, set kycStatus to pending
    let isKycPending = false;
    if (aadhaarImage || livePhotoUrl || (driverProfile && driverProfile.licenceFrontUrl)) {
      fields.kycStatus = 'pending';
      isKycPending = true;
    }

    const user = await User.findByIdAndUpdate(req.user.id, fields, { new: true, runValidators: true });

    if (isKycPending) {
      const { notifyAdmins } = require('../utils/notification');
      await notifyAdmins({
        title: '📋 New KYC Submission',
        message: `${user.name} has updated documents for verification.`,
        type: 'kyc_pending',
        relatedId: user._id,
        io: req.app.get('io')
      });
    }

    res.status(200).json({ success: true, message: req.t('general.success'), data: _formatUser(user) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Update location
// @route   PUT /api/auth/location
exports.updateLocation = async (req, res) => {
  try {
    const { coordinates, address } = req.body;
    if (!coordinates || coordinates.length !== 2) {
      return res.status(400).json({ success: false, message: 'Provide valid [longitude, latitude]' });
    }
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { location: { type: 'Point', coordinates, address: address || '' } },
      { new: true }
    );
    res.status(200).json({ success: true, message: req.t('general.success'), data: _formatUser(user) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// Helper - format user for response (omit sensitive)
const _formatUser = (user) => {
  let maskedAadhaar = user.aadhaarNumber;
  if (user.kycStatus === 'approved' && user.aadhaarNumber && user.aadhaarNumber.length >= 12) {
    maskedAadhaar = 'XXXXXXXX' + user.aadhaarNumber.slice(-4);
  }

  return {
    _id: user._id,
    id: user._id,
    name: user.name,
    phone: user.phone,
    email: user.email || null,
    role: user.role,
    skills: user.skills,
    village: user.village,
    companyName: user.companyName,
    businessArea: user.businessArea,
    language: user.language,
    location: user.location,
    profileImage: user.profileImage,
    rating: user.rating,
    completedJobsCount: user.completedJobsCount,
    experienceDays: user.experienceDays,
    experienceYears: user.experienceYears,
    aadhaarNumber: maskedAadhaar,
    aadhaarImage: user.aadhaarImage,
    aadhaarBackImage: user.aadhaarBackImage,
    livePhotoUrl: user.livePhotoUrl,
    kycStatus: user.kycStatus,
    kycNote: user.kycNote,
    isPhoneVerified: user.isPhoneVerified,
    isBlocked: user.isBlocked,
    workerType: user.workerType,
    driverProfile: user.driverProfile,
    referralCode: user.referralCode,
    referralEarnings: user.referralEarnings,
    walletBalance: user.walletBalance,
    referralCount: user.referralCount,
    recruiterVerification: user.recruiterVerification,
    createdAt: user.createdAt
  };
};

// @desc    Update FCM Token
// @route   PUT /api/auth/fcm-token
// @access  Private
exports.updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ success: false, message: 'Token required' });

    await User.findByIdAndUpdate(req.user.id, { fcmToken });
    res.status(200).json({ success: true, message: req.t('general.success') });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to update token' });
  }
};

// @desc    Delete user account (Soft delete)
// @route   POST /api/auth/delete-account
// @access  Private
exports.deleteAccount = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: req.t('general.not_found') });
    }

    if (user.role === 'admin') {
      return res.status(403).json({ success: false, message: 'Admin accounts cannot be deleted' });
    }

    if (
      user.email === 'demo@kaamkaaz.org' ||
      user.email === 'recruiter.demo@kaamkaaz.org' ||
      user.email === 'worker.demo@kaamkaaz.org' ||
      user.phone === '9999999999' ||
      user.phone === '9000000001' ||
      user.phone === '9000000002'
    ) {
      return res.status(403).json({ success: false, message: 'Demo accounts cannot be deleted' });
    }

    user.isDeleted = true;
    user.deletedAt = new Date();
    await user.save();

    res.status(200).json({
      success: true,
      message: req.t('general.deleted')
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// @desc    Supabase Reset Password
// @route   POST /api/auth/supabase-reset-password
exports.supabaseResetPassword = async (req, res) => {
  try {
    const { idToken, newPassword } = req.body;
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Min 6 characters required'
      });
    }
    const { data: { user: supabaseUser }, error } = await supabase.auth.getUser(idToken);
    if (error || !supabaseUser) {
      return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
    }

    // Find user in MongoDB by Supabase UID, Phone, or Email
    let user = await User.findOne({ supabaseUid: supabaseUser.id });

    if (!user && supabaseUser.phone) {
      const phone = supabaseUser.phone.replace('+91', '');
      user = await User.findOne({ phone });
    }

    if (!user && supabaseUser.email) {
      user = await User.findOne({ email: supabaseUser.email.toLowerCase() });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Account not found'
      });
    }

    // If MongoDB user doesn't have supabaseUid set, link it now
    if (!user.supabaseUid) {
      user.supabaseUid = supabaseUser.id;
    }

    // Hash password (will be handled by pre-save hook if we set it on user.password)
    user.password = newPassword;
    user.resetToken = null;
    user.resetTokenExpiry = null;
    await user.save();

    res.json({
      success: true,
      message: 'Password reset successfully'
    });
  } catch (e) {
    console.error('Supabase Reset Password Error:', e.message);
    res.status(500).json({
      success: false,
      message: 'Reset failed'
    });
  }
};

// @desc    Reset Password
// @route   POST /api/auth/reset-password
// @access  Public
exports.resetPassword = async (req, res) => {
  try {
    const { resetToken, newPassword } = req.body;
    if (!resetToken || !newPassword) {
      return res.status(400).json({ success: false, message: 'Token and new password are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }

    const user = await User.findOne({
      resetToken,
      resetTokenExpiry: { $gt: new Date() }
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Reset link expired. Please start again.'
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(12);
    user.password = await bcrypt.hash(newPassword, salt);

    // Clear reset fields
    user.resetToken = null;
    user.resetTokenExpiry = null;

    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password reset successfully'
    });
  } catch (err) {
    console.error('Reset Password Error:', err.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// @desc    Change Password
// @route   PUT /api/auth/change-password
// @access  Private
exports.changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    if (!oldPassword || !newPassword) {
      return res.status(400).json({ success: false, message: 'Old and new passwords are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'New password must be at least 6 characters' });
    }

    const user = await User.findById(req.user.id).select('+password');
    if (!user) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    const isMatch = await user.matchPassword(oldPassword);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Incorrect old password' });
    }

    // Set new password (will be hashed by pre-save hook)
    user.password = newPassword;
    await user.save();

    res.status(200).json({ success: true, message: req.t('general.success') });
  } catch (err) {
    console.error('Change Password Error:', err.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// @desc    Add a portfolio item
// @route   POST /api/auth/portfolio
// @access  Private
exports.addPortfolioItem = async (req, res) => {
  try {
    const { description, descriptionHindi, descriptionEnglish, mediaUrl, mediaType, publicId } = req.body;

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const descHindi = description || descriptionHindi || '';
    const descEnglish = description || descriptionEnglish || '';

    user.portfolio.push({
      descriptionHindi: descHindi,
      descriptionEnglish: descEnglish,
      mediaUrl: mediaUrl || '',
      mediaType: mediaType || 'text',
      publicId: publicId || ''
    });

    await user.save();

    res.status(201).json({
      success: true,
      message: 'Portfolio item added successfully',
      data: user.portfolio
    });
  } catch (err) {
    console.error('Add Portfolio Item Error:', err.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// @desc    Delete a portfolio item
// @route   DELETE /api/auth/portfolio/:itemId
// @access  Private
exports.deletePortfolioItem = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const item = user.portfolio.id(req.params.itemId);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Portfolio item not found' });
    }

    // Delete image/video from Cloudinary if it exists
    if (item.publicId) {
      const { deleteImage } = require('../utils/cloudinaryHelper');
      await deleteImage(item.publicId);
    }

    user.portfolio.pull(req.params.itemId);
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Portfolio item deleted successfully',
      data: user.portfolio
    });
  } catch (err) {
    console.error('Delete Portfolio Item Error:', err.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// @desc    Add / Update user email (both MongoDB and Supabase Auth)
// @route   POST /api/auth/add-email
// @access  Private
exports.addEmail = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required' });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ success: false, message: 'Invalid email address' });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const targetEmail = email.toLowerCase();

    // Check if email already registered by another user in MongoDB
    const existing = await User.findOne({ email: targetEmail, _id: { $ne: user._id } });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Email already in use by another account' });
    }

    // Step 1: Ensure we have the correct supabaseUid
    let supabaseUid = user.supabaseUid;

    // Fetch all users in Supabase Auth to find matches by phone or email
    const { data: listData, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) {
      console.error('Failed to list Supabase users:', listError.message);
      return res.status(500).json({ success: false, message: `Auth service error: ${listError.message}` });
    }

    const formattedPhone = `+91${user.phone}`;

    // Find if a user already exists in Supabase by phone or email
    const matchedByPhone = listData.users.find(u => u.phone === formattedPhone);
    const matchedByEmail = listData.users.find(u => u.email && u.email.toLowerCase() === targetEmail);

    if (matchedByEmail && matchedByPhone && matchedByEmail.id !== matchedByPhone.id) {
      // The email is already taken by a different account in Supabase Auth
      return res.status(400).json({
        success: false,
        message: 'This email is already registered with another account in the authentication service'
      });
    }

    if (matchedByEmail && !matchedByPhone) {
      // The email belongs to someone else who doesn't have this phone number
      return res.status(400).json({
        success: false,
        message: 'This email is already in use by another account'
      });
    }

    // If we have a matching user in Supabase by phone, we should use their ID
    if (matchedByPhone) {
      supabaseUid = matchedByPhone.id;
    }

    // Step 2: Create or update the Supabase Auth user
    if (supabaseUid) {
      // Update existing Supabase user's email
      const { error: updateError } = await supabase.auth.admin.updateUserById(
        supabaseUid,
        { email: targetEmail, email_confirm: true }
      );
      if (updateError) {
        console.error('Failed to update email in Supabase:', updateError.message);
        return res.status(400).json({
          success: false,
          message: `Failed to update email in authentication service: ${updateError.message}`
        });
      }
    } else {
      // Create new Supabase user
      const { data: createData, error: createError } = await supabase.auth.admin.createUser({
        email: targetEmail,
        phone: formattedPhone,
        email_confirm: true,
        user_metadata: { name: user.name }
      });
      if (createError) {
        console.error('Failed to create Supabase user:', createError.message);
        return res.status(400).json({
          success: false,
          message: `Failed to create authentication account: ${createError.message}`
        });
      }
      if (createData && createData.user) {
        supabaseUid = createData.user.id;
      }
    }

    // Step 3: Save to MongoDB
    user.email = targetEmail;
    user.supabaseUid = supabaseUid;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Email updated successfully',
      data: _formatUser(user)
    });
  } catch (err) {
    console.error('Add Email Error:', err.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

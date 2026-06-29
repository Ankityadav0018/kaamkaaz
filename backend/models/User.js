const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide a name'],
    trim: true,
    maxlength: [60, 'Name cannot exceed 60 characters']
  },
  phone: {
    type: String,
    required: [true, 'Please provide a phone number'],
    unique: true,
    match: [/^\d{10}$/, 'Please provide a valid 10-digit phone number']
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
    unique: true,
    sparse: true,
    match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Please provide a valid email address']
  },
  password: {
    type: String,
    required: [true, 'Please provide a password'],
    minlength: 6,
    select: false
  },
  role: {
    type: String,
    enum: ['worker', 'recruiter', 'admin'],
    default: 'worker'
  },
  // Worker-specific
  skills: [{ type: String, trim: true }],
  village: { type: String, trim: true, default: '' },
  experienceYears: { type: Number, default: 0 },
  aadhaarNumber: {
    type: String,
    trim: true,
    unique: true,
    sparse: true // Allows multiple null/empty values if not provided, but unique if it IS provided
  },
  aadhaarImage: { type: String, default: '' },      // Front
  aadhaarImagePublicId: { type: String, default: '' },
  aadhaarBackImage: { type: String, default: '' },  // Back
  aadhaarBackImagePublicId: { type: String, default: '' },
  livePhotoUrl: { type: String, default: '' },      // Selfie
  livePhotoPublicId: { type: String, default: '' },
  skillProofImage: { type: String, default: '' },
  skillProofPublicId: { type: String, default: '' },
  // Recruiter-specific
  companyName: { type: String, trim: true, default: '' },
  businessArea: { type: String, trim: true, default: '' },
  // Common
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], default: [0, 0] }, // [lon, lat]
    address: { type: String, default: '' }
  },
  profileImage: { type: String, default: '' },
  profileImagePublicId: { type: String, default: '' },
  language: {
    type: String,
    enum: ['en', 'hi', 'bn', 'te', 'mr', 'ta', 'gu', 'pa', 'or', 'kn'],
    default: 'hi'
  },
  urgentAlertsEnabled: { type: Boolean, default: true },
  urgentAlertCountToday: { type: Number, default: 0 },
  urgentAlertLastSentAt: { type: Date, default: null },
  rating: {
    average: { type: Number, default: 0, min: 0, max: 5 },
    count: { type: Number, default: 0 }
  },
  completedJobsCount: { type: Number, default: 0, min: 0 },
  experienceDays: { type: Number, default: 0, min: 0 },
  // KYC / Status
  kycStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'not_submitted'],
    default: 'not_submitted'
  },
  kycNote: { type: String, default: '' },
  isPhoneVerified: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  isBlocked: { type: Boolean, default: false },
  otp: {
    code: String,
    expiresAt: Date
  },
  portfolio: [{
    descriptionHindi: { type: String, default: '' },
    descriptionEnglish: { type: String, default: '' },
    mediaUrl: { type: String, default: '' },
    mediaType: { type: String, enum: ['image', 'video', 'text'], default: 'text' },
    publicId: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
  }],
  supabaseUid: { type: String, default: null },
  resetToken: { type: String, default: null },
  resetTokenExpiry: { type: Date, default: null },
  // Worker sub-type
  workerType: {
    type: String,
    enum: ['general', 'driver'],
    default: 'general'
  },

  // Driver-specific profile (only relevant when workerType === 'driver')
  driverProfile: {
    vehicleTypes: [{ type: String }],
    experienceYears: { type: Number, default: 0 },
    languages: [{ type: String }],
    willingToOutstation: { type: Boolean, default: false },
    hasOwnVehicle: { type: Boolean, default: false },
    ownVehicleType: { type: String, default: '' },
    ownVehicleRegNumber: { type: String, default: '' },
    licenceFrontUrl: { type: String, default: '' },
    licenceFrontPublicId: { type: String, default: '' },
    licenceBackUrl: { type: String, default: '' },
    licenceBackPublicId: { type: String, default: '' },
    aadhaarUrl: { type: String, default: '' },
    aadhaarPublicId: { type: String, default: '' },
    rcBookUrl: { type: String, default: '' },
    rcBookPublicId: { type: String, default: '' },
    policeVerificationUrl: { type: String, default: '' },
    policeVerificationPublicId: { type: String, default: '' },
    passportPhotoUrl: { type: String, default: '' },
    passportPhotoPublicId: { type: String, default: '' },
    kycStatus: {
      type: String,
      enum: ['not_submitted', 'pending', 'verified', 'rejected'],
      default: 'not_submitted'
    },
    kycRejectionReason: { type: String, default: '' },
    kycSubmittedAt: { type: Date },
    kycVerifiedAt: { type: Date }
  },

  fcmToken: { type: String, default: '' },

  // Referral System
  referralCode: {
    type: String,
    unique: true,
    sparse: true
  },
  referredBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  referralCount: {
    type: Number,
    default: 0
  },
  referralEarnings: {
    type: Number,
    default: 0
  },
  walletBalance: {
    type: Number,
    default: 0
  },
  verifiedSkills: [String],
  recruiterVerification: {
    status: {
      type: String,
      enum: ['not_submitted', 'pending', 'verified', 'suspended'],
      default: 'not_submitted'
    },
    businessType: {
      type: String,
      enum: ['individual', 'contractor', 'factory', 'farm', 'company', 'household', 'other']
    },
    businessName: String,
    areaOfOperation: String,
    purposeNote: { type: String, maxlength: 200 },
    verifiedAt: Date,
    suspendedReason: String,

    // NEW document fields:
    aadhaarNumber: { type: String, default: null },
    aadhaarFrontUrl: { type: String, default: null },
    aadhaarFrontPublicId: { type: String, default: null },
    aadhaarBackUrl: { type: String, default: null },
    aadhaarBackPublicId: { type: String, default: null },
    selfieUrl: { type: String, default: null },
    selfiePublicId: { type: String, default: null },
    kycSubmittedAt: { type: Date, default: null },
  },
  isDeleted: { type: Boolean, default: false },
  deletedAt: { type: Date, default: null },

  // ── Admin security fields (Layers 2 / 3) ─────────────────────────────────────────────────────────────────────────────
  // Layer 2: TOTP secret (base32, stored for Google Authenticator)
  totpSecret: { type: String, default: null, select: false },
  // Layer 3: list of IPs this admin has confirmed as trusted
  knownIps: { type: [String], default: [] },
  // Layer 3: admin's IANA timezone (e.g. 'Asia/Kolkata') for off-hours detection
  timezone: { type: String, default: 'Asia/Kolkata' },
  // Layer 2: set when OTP fails 3× — admin locked until this date
  adminLockUntil: { type: Date, default: null },

  // ── Session security (Section 1.2) ────────────────────────────────────────
  // Increment this on password reset / logout-all to invalidate ALL existing JWTs
  tokenVersion: { type: Number, default: 0 }
}, { timestamps: true });

// Geospatial index
userSchema.index({ location: '2dsphere' });

// Hash password — upgraded to salt rounds 12 (Section 1.1)
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.getSignedJwtToken = function () {
  return jwt.sign(
    { id: this._id, role: this.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

userSchema.methods.matchPassword = async function (entered) {
  return await bcrypt.compare(entered, this.password);
};

// Global query middleware to exclude deleted users
userSchema.pre(/^find/, function (next) {
  this.find({ isDeleted: { $ne: true } });
  next();
});

userSchema.pre('countDocuments', function (next) {
  this.find({ isDeleted: { $ne: true } });
  next();
});

userSchema.pre('aggregate', function (next) {
  this.pipeline().unshift({ $match: { isDeleted: { $ne: true } } });
  next();
});

module.exports = mongoose.model('User', userSchema);

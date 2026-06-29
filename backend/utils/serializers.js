/**
 * serializers.js — Section 2.3: Role-specific DTO serializers
 *
 * Prevents cross-role data leakage by returning only the fields
 * appropriate for each viewer's role.
 *
 * Usage:
 *   const { workerView, recruiterView, adminView } = require('../utils/serializers');
 *   res.json({ data: workerView(user) });
 */

// ─── Worker view of their OWN profile ────────────────────────────────────────
exports.workerSelfView = (user) => ({
  _id:              user._id,
  id:               user._id,
  name:             user.name,
  phone:            user.phone,   // shown to self only
  email:            user.email,
  role:             user.role,
  skills:           user.skills,
  village:          user.village,
  language:         user.language,
  location:         user.location,
  profileImage:     user.profileImage,
  rating:           user.rating,
  completedJobsCount: user.completedJobsCount,
  experienceDays:   user.experienceDays,
  experienceYears:  user.experienceYears,
  aadhaarNumber:    user.aadhaarNumber
    ? (user.kycStatus === 'approved' ? 'XXXXXXXX' + user.aadhaarNumber.toString().slice(-4) : '[ENCRYPTED]')
    : null,
  kycStatus:        user.kycStatus,
  kycNote:          user.kycNote,
  isPhoneVerified:  user.isPhoneVerified,
  isBlocked:        user.isBlocked,
  workerType:       user.workerType,
  driverProfile:    user.driverProfile,
  referralCode:     user.referralCode,
  referralEarnings: user.referralEarnings,
  walletBalance:    user.walletBalance,
  referralCount:    user.referralCount,
  portfolio:        user.portfolio,
  createdAt:        user.createdAt
});

// ─── Recruiter view of a worker (public browsing, before acceptance) ──────────
exports.workerPublicView = (user) => ({
  _id:              user._id,
  name:             user.name,
  // phone OMITTED — revealed only after acceptance via workerAcceptedView
  role:             'worker',
  skills:           user.skills,
  village:          user.village,
  location: user.location
    ? { address: user.location.address, coordinates: user.location.coordinates }
    : null,
  profileImage:     user.profileImage,
  rating:           user.rating,
  completedJobsCount: user.completedJobsCount,
  experienceDays:   user.experienceDays,
  experienceYears:  user.experienceYears,
  kycStatus:        user.kycStatus,
  workerType:       user.workerType,
  // Internal notes, budget, pipeline stage — OMITTED entirely
});

// ─── After acceptance — phone revealed ───────────────────────────────────────
exports.workerAcceptedView = (user) => ({
  ...exports.workerPublicView(user),
  phone: user.phone
});

// ─── Recruiter view of their OWN profile ─────────────────────────────────────
exports.recruiterSelfView = (user) => ({
  _id:              user._id,
  id:               user._id,
  name:             user.name,
  phone:            user.phone,
  email:            user.email,
  role:             user.role,
  companyName:      user.companyName,
  businessArea:     user.businessArea,
  language:         user.language,
  location:         user.location,
  profileImage:     user.profileImage,
  rating:           user.rating,
  kycStatus:        user.kycStatus,
  recruiterVerification: user.recruiterVerification
    ? {
        status:       user.recruiterVerification.status,
        businessType: user.recruiterVerification.businessType,
        businessName: user.recruiterVerification.businessName,
        areaOfOperation: user.recruiterVerification.areaOfOperation,
        // aadhaarNumber OMITTED — sensitive
        verifiedAt:   user.recruiterVerification.verifiedAt
      }
    : null,
  walletBalance:    user.walletBalance,
  referralCode:     user.referralCode,
  createdAt:        user.createdAt
});

// ─── Worker view of a recruiter (only what is needed to trust them) ───────────
exports.recruiterPublicView = (user) => ({
  _id:         user._id,
  name:        user.name,
  companyName: user.companyName,
  businessArea: user.businessArea,
  profileImage: user.profileImage,
  rating:      user.rating,
  recruiterVerification: user.recruiterVerification
    ? { status: user.recruiterVerification.status }
    : null
  // Analytics, applicant lists, contact info — OMITTED
});

// ─── Admin view — full data ───────────────────────────────────────────────────
exports.adminView = (user) => ({
  ...user.toObject ? user.toObject() : user
});

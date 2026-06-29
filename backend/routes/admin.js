/**
 * routes/admin.js — Admin API Routes
 *
 * Security middleware chain on all data routes:
 *   adminSession  (Layer 5) → adminAnomaly (Layer 3) → adminIntent (Layer 4)
 *
 * Unauthenticated auth routes (Layer 1 + 2):
 *   POST /api/admin/auth/login
 *   POST /api/admin/auth/verify-otp
 *   POST /api/admin/auth/logout
 *   POST /api/admin/auth/setup-totp
 */

const express = require('express');
const router  = express.Router();

// ── Controllers ───────────────────────────────────────────────────────────────
const {
  getStats,
  getAllUsers,
  getPendingKYC,
  reviewKYC,
  toggleBlock,
  warnUser,
  getAllJobs,
  getPendingRecruiters,
  getRecruiterDetails,
  updateRecruiterVerification,
  getAnalytics,
  getPendingWithdrawals,
  processWithdrawal,
  getWithdrawalHistory
} = require('../controllers/adminController');

const {
  adminLogin,
  adminVerifyOtp,
  adminLogout,
  setupTotp
} = require('../controllers/adminAuthController');

const { adminGetDisputes, adminUpdateDispute, getDisputeStats } = require('../controllers/disputeController');
const { getAllSosAlerts, updateSosStatus }                      = require('../controllers/sosController');

// ── Security Middleware (Layers 3, 4, 5) ─────────────────────────────────────
const adminSession = require('../middleware/adminSession');  // Layer 5
const adminAnomaly = require('../middleware/adminAnomaly');  // Layer 3
const adminIntent  = require('../middleware/adminIntent');   // Layer 4

// Full chain applied to all protected admin data routes
const adminGuard = [adminSession, adminAnomaly, adminIntent];

// ─────────────────────────────────────────────────────────────────────────────
// UNAUTHENTICATED: Layer 1 + 2 Auth Endpoints
// These do NOT use adminGuard — they ARE the login flow.
// ─────────────────────────────────────────────────────────────────────────────

router.post('/auth/login',       adminLogin);
router.post('/auth/verify-otp',  adminVerifyOtp);
router.post('/auth/logout',      adminLogout);
router.post('/auth/setup-totp',  adminSession, setupTotp); // requires full token

// ─────────────────────────────────────────────────────────────────────────────
// PROTECTED: All admin data routes — full 5-layer guard
// ─────────────────────────────────────────────────────────────────────────────

router.get('/stats',     adminGuard, getStats);
router.get('/analytics', adminGuard, getAnalytics);

// User management
router.get('/users',                  adminGuard, getAllUsers);
router.put('/users/:userId/block',    adminGuard, toggleBlock);
router.post('/users/:userId/warn',    adminGuard, warnUser);

// KYC
router.get('/kyc-pending',            adminGuard, getPendingKYC);
router.put('/kyc/:userId',            adminGuard, reviewKYC);

// Jobs
router.get('/jobs',                   adminGuard, getAllJobs);

// Recruiters
router.get('/recruiters/pending',         adminGuard, getPendingRecruiters);
router.get('/recruiters/:userId',         adminGuard, getRecruiterDetails);
router.patch('/recruiters/:userId/verify', adminGuard, updateRecruiterVerification);

// Disputes
router.get('/disputes',       adminGuard, adminGetDisputes);
router.get('/disputes/stats', adminGuard, getDisputeStats);
router.patch('/disputes/:id', adminGuard, adminUpdateDispute);

// Withdrawals
router.get('/withdrawals/pending',                      adminGuard, getPendingWithdrawals);
router.get('/withdrawals/history',                      adminGuard, getWithdrawalHistory);
router.post('/withdrawals/:transactionId/process',      adminGuard, processWithdrawal);

// SOS alerts
router.get('/sos',        adminGuard, getAllSosAlerts);
router.patch('/sos/:id',  adminGuard, updateSosStatus);

// ── Section 7: Security Dashboard ────────────────────────────────────────────
const { getSecurityDashboard } = require('../controllers/securityController');
router.get('/security-dashboard', adminGuard, getSecurityDashboard);

module.exports = router;


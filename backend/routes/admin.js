const express = require('express');
const router = express.Router();
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
const { protect, authorize } = require('../middleware/auth');

router.use(protect, authorize('admin'));

const { adminGetDisputes, adminUpdateDispute, getDisputeStats } = require('../controllers/disputeController');
const { getAllSosAlerts, updateSosStatus } = require('../controllers/sosController');

router.get('/stats', getStats);
router.get('/analytics', getAnalytics);
router.get('/users', getAllUsers);
router.get('/kyc-pending', getPendingKYC);
router.put('/kyc/:userId', reviewKYC);
router.put('/users/:userId/block', toggleBlock);
router.post('/users/:userId/warn', warnUser);
router.get('/jobs', getAllJobs);
router.get('/recruiters/pending', getPendingRecruiters);
router.get('/recruiters/:userId', getRecruiterDetails);
router.patch('/recruiters/:userId/verify', updateRecruiterVerification);

// Dispute management
router.get('/disputes', adminGetDisputes);
router.get('/disputes/stats', getDisputeStats);
router.patch('/disputes/:id', adminUpdateDispute);

// Withdrawal management
router.get('/withdrawals/pending', getPendingWithdrawals);
router.get('/withdrawals/history', getWithdrawalHistory);
router.post('/withdrawals/:transactionId/process', processWithdrawal);

// SOS alerts
router.get('/sos', getAllSosAlerts);
router.patch('/sos/:id', updateSosStatus);

module.exports = router;

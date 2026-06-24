const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {

  getDriverProfile,
  saveDriverProfile,
  getNearbyDrivers,
  getPublicDriverProfile,
  adminGetPendingDrivers,
  adminReviewDriverKyc,
} = require('../controllers/driverController');

// Worker routes
router.get('/profile', protect, authorize('worker'), getDriverProfile);
router.post('/profile', protect, authorize('worker'), saveDriverProfile);

// Recruiter routes
router.get('/nearby', protect, authorize('recruiter'), getNearbyDrivers);
router.get('/:driverId', protect, authorize('recruiter', 'admin'), getPublicDriverProfile);

// Admin routes
router.get('/kyc/pending', protect, authorize('admin'), adminGetPendingDrivers);
router.patch('/kyc/review/:userId', protect, authorize('admin'), adminReviewDriverKyc);

module.exports = router;

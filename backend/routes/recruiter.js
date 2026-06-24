const express = require('express');
const router = express.Router();
const { 
  getRecruiterStats, 
  getPastWorkers, 
  reinviteWorker,
  submitOnboarding,
  getVerificationStatus
} = require('../controllers/recruiterController');
const { protect, authorize } = require('../middleware/auth');

router.use(protect, authorize('recruiter'));

router.get('/stats', getRecruiterStats);
router.get('/past-workers', getPastWorkers);
router.post('/reinvite/:workerId', reinviteWorker);
router.post('/onboarding', submitOnboarding);
router.get('/verification-status', getVerificationStatus);

module.exports = router;

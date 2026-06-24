const express = require('express');
const router = express.Router();
const {
  applyForJob, getJobApplications, getMyApplications,
  acceptApplication, rejectApplication, withdrawApplication, getWorkerProfile,
  getRecruiterApplications
} = require('../controllers/applicationController');
const { protect, authorize } = require('../middleware/auth');

router.post('/', protect, authorize('worker'), applyForJob);
router.get('/my-applications', protect, authorize('worker'), getMyApplications);
router.get('/recruiter/all', protect, authorize('recruiter'), getRecruiterApplications);
router.get('/job/:jobId', protect, authorize('recruiter', 'admin'), getJobApplications);
router.put('/:id/accept', protect, authorize('recruiter'), acceptApplication);
router.put('/:id/reject', protect, authorize('recruiter'), rejectApplication);
router.get('/:id/worker-profile', protect, authorize('recruiter'), getWorkerProfile);
router.delete('/:id', protect, authorize('worker'), withdrawApplication);

module.exports = router;

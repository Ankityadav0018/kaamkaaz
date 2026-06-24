const express = require('express');
const router = express.Router();
const { postJob, getNearbyJobs, getJobById, getMyJobs, updateJobStatus, deleteJob, getJobShareText, updateJob, verifyUrgentPayment } = require('../controllers/jobController');
const { protect, authorize } = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

const { checkRecruiterVerification } = require('../middleware/recruiterVerification');

router.post('/', protect, authorize('recruiter'), checkRecruiterVerification, upload.array('images', 5), postJob);
router.get('/nearby', protect, getNearbyJobs);
router.get('/my-jobs', protect, authorize('recruiter', 'admin'), getMyJobs);
router.get('/:id/share-text', protect, getJobShareText);
router.get('/:id', protect, getJobById);
router.put('/:id', protect, authorize('recruiter'), upload.array('images', 5), updateJob);
router.post('/:id/verify-urgent-payment', protect, authorize('recruiter'), verifyUrgentPayment);
router.put('/:id/status', protect, authorize('recruiter', 'admin'), updateJobStatus);
router.delete('/:id', protect, authorize('recruiter', 'admin'), deleteJob);

module.exports = router;

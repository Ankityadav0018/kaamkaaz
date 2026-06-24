const express = require('express');
const router = express.Router();
const { getUploadUrl, submitKyc, reviewKyc } = require('../controllers/kycController');
const { protect, authorize } = require('../middleware/auth');

router.post('/upload-url', protect, getUploadUrl);
router.post('/submit', protect, submitKyc);
router.patch('/review/:userId', protect, authorize('admin'), reviewKyc);

module.exports = router;

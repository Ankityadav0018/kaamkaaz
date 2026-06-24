const express = require('express');
const router = express.Router();
const { getUploadSignature } = require('../controllers/uploadController');
const { protect, optionalProtect } = require('../middleware/auth');
const rateLimit = require('express-rate-limit');

// Rate limiting for upload signature requests (prevent spam)
const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // Limit each IP to 30 signature requests per window
  message: {
    success: false,
    message: 'Too many upload requests. Please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * All upload routes are optionally protected and rate-limited
 */
router.get('/signature', optionalProtect, uploadLimiter, getUploadSignature);

module.exports = router;

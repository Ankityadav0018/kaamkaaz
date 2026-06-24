const express = require('express');
const router = express.Router();
const { getPublicProfile, searchProfiles, toggleUrgentAlerts } = require('../controllers/userController');
const { updateFcmToken } = require('../controllers/authController');
const { protect } = require('../middleware/auth');

router.get('/search', protect, searchProfiles);
router.get('/public/:id', protect, getPublicProfile);
router.post('/fcm-token', protect, updateFcmToken);
router.put('/toggle-urgent-alerts', protect, toggleUrgentAlerts);

module.exports = router;

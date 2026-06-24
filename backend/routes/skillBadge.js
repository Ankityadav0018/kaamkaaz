const express = require('express');
const router = express.Router();
const { 
  requestSkillBadge, 
  getMySkillBadges, 
  getPendingSkillBadges, 
  updateSkillBadgeStatus 
} = require('../controllers/skillBadgeController');
const { protect, authorize } = require('../middleware/auth');

router.use(protect);

// Worker routes
router.post('/request', requestSkillBadge);
router.get('/my', getMySkillBadges);

// Admin routes
router.get('/admin/pending', authorize('admin'), getPendingSkillBadges);
router.patch('/admin/:id', authorize('admin'), updateSkillBadgeStatus);

module.exports = router;

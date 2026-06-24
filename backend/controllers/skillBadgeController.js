const SkillBadge = require('../models/SkillBadge');
const User = require('../models/User');
const { createNotification } = require('../utils/notification');

// @desc    Request a skill badge
// @route   POST /api/skill-badges/request
// @access  Private (Worker)
exports.requestSkillBadge = async (req, res) => {
  try {
    const { skill, documentUrl, documentPublicId } = req.body;

    if (!skill) {
      return res.status(400).json({ success: false, message: 'Skill is required' });
    }

    // Check if already exists (pending or verified)
    const existing = await SkillBadge.findOne({ 
      workerId: req.user.id, 
      skill,
      status: { $in: ['pending', 'verified'] }
    });

    if (existing) {
      return res.status(400).json({ 
        success: false, 
        message: existing.status === 'verified' 
          ? 'You already have this badge verified' 
          : 'A request for this badge is already pending' 
      });
    }

    const badge = await SkillBadge.create({
      workerId: req.user.id,
      skill,
      documentUrl,
      documentPublicId
    });

    // Notify Admin of pending skill badge request
    try {
      const { notifyAdmins } = require('../utils/notification');
      const worker = await User.findById(req.user.id);
      await notifyAdmins({
        title: '🏅 New Skill Badge Request',
        message: `${worker ? worker.name : 'A worker'} has requested verification for "${skill}".`,
        type: 'skill_badge_pending',
        relatedId: badge._id,
        io: req.app.get('io')
      });
    } catch (notifyErr) {
      console.error('❌ Skill badge admin notification failed:', notifyErr.message);
    }

    res.status(201).json({ success: true, data: badge });
  } catch (err) {
    if (err.code === 11000) {
        return res.status(400).json({ success: false, message: 'You have already submitted a request for this skill' });
    }
    res.status(500).json({ success: false, message: req.t('general.server_error'), error: err.message });
  }
};

// @desc    Get my skill badges
// @route   GET /api/skill-badges
// @access  Private (Worker)
exports.getMySkillBadges = async (req, res) => {
  try {
    const badges = await SkillBadge.find({ workerId: req.user.id }).sort('-createdAt');
    res.status(200).json({ success: true, data: badges });
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error') });
  }
};

// @desc    Get pending skill badges (Admin)
// @route   GET /api/skill-badges/admin/pending
// @access  Private (Admin)
exports.getPendingSkillBadges = async (req, res) => {
  try {
    const badges = await SkillBadge.find({ status: 'pending' })
      .populate('workerId', 'name phone')
      .sort('createdAt');
    
    res.status(200).json({ success: true, data: badges });
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error') });
  }
};

// @desc    Update skill badge status (Admin)
// @route   PATCH /api/skill-badges/admin/:id
// @access  Private (Admin)
exports.updateSkillBadgeStatus = async (req, res) => {
  try {
    const { action, adminNote } = req.body;
    const badge = await SkillBadge.findById(req.params.id);

    if (!badge) {
      return res.status(404).json({ success: false, message: 'Badge request not found' });
    }

    if (action === 'verify') {
      badge.status = 'verified';
      badge.verifiedAt = Date.now();
      badge.adminNote = adminNote || '';
      
      // Add skill to user's verifiedSkills
      await User.findByIdAndUpdate(badge.workerId, {
        $addToSet: { verifiedSkills: badge.skill }
      });

      // Notification
      await createNotification({
        userId: badge.workerId,
        title: '🏅 Skill Badge Verified!',
        message: `Your ${badge.skill} badge has been verified! It will now show on your profile.`,
        type: 'skill_verified'
      });

    } else if (action === 'reject') {
      badge.status = 'rejected';
      badge.adminNote = adminNote || 'Documents provided were insufficient or invalid.';

      // Notification
      await createNotification({
        userId: badge.workerId,
        title: '❌ Skill Badge Rejected',
        message: `Your ${badge.skill} badge request was rejected. Reason: ${badge.adminNote}`,
        type: 'skill_rejected'
      });
    } else {
      return res.status(400).json({ success: false, message: 'Invalid action. Use verify or reject.' });
    }

    await badge.save();
    res.status(200).json({ success: true, data: badge });
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error') });
  }
};

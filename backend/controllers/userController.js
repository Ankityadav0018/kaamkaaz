const User = require('../models/User');

// @desc    Get public profile of a user
// @route   GET /api/users/public/:id
exports.getPublicProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('-password -otp -fcmToken -documentId -documentImage -createdAt -updatedAt -__v');
      
    if (!user) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    const profileData = user.toObject();
    
    // Hide personal details
    delete profileData.phone;
    if (profileData.kycStatus) delete profileData.kycStatus;
    
    res.status(200).json({ success: true, data: profileData });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Search profiles by name
// @route   GET /api/users/search
exports.searchProfiles = async (req, res) => {
  try {
    const { name, role, page = 1, limit = 20 } = req.query;
    if (!name) return res.status(400).json({ success: false, message: 'Search query is required' });

    let query = {
      $or: [
        { name: { $regex: name, $options: 'i' } },
        { phone: { $regex: name, $options: 'i' } }
      ],
      isBlocked: false,
      role: { $in: ['worker', 'recruiter'] }
    };
    
    if (role) {
      query.role = role;
    }


    
    const users = await User.find(query)
      .select('_id name role phone profileImage village skills rating experienceDays completedJobsCount')
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));


    res.status(200).json({ success: true, count: users.length, data: users });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Toggle Urgent Alerts
// @route   PUT /api/users/toggle-urgent-alerts
// @access  Private
exports.toggleUrgentAlerts = async (req, res) => {
  try {
    const { enabled } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    
    user.urgentAlertsEnabled = Boolean(enabled);
    await user.save();
    
    res.status(200).json({ success: true, data: { urgentAlertsEnabled: user.urgentAlertsEnabled } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};


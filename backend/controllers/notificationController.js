const Notification = require('../models/Notification');

// @desc    Get notifications for current user
// @route   GET /api/notifications
exports.getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 30 } = req.query;
    const total = await Notification.countDocuments({ userId: req.user.id });
    const notifications = await Notification.find({ userId: req.user.id })
      .sort({ createdAt: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));
    const unreadCount = await Notification.countDocuments({ userId: req.user.id, isRead: false });
    res.status(200).json({ success: true, count: notifications.length, total, unreadCount, data: notifications });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Mark notification as read
// @route   PUT /api/notifications/:id/read
exports.markRead = async (req, res) => {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      { isRead: true }
    );
    res.status(200).json({ success: true, message: 'Marked as read' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/read-all
exports.markAllRead = async (req, res) => {
  try {
    await Notification.updateMany({ userId: req.user.id, isRead: false }, { isRead: true });
    res.status(200).json({ success: true, message: 'All notifications marked as read' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

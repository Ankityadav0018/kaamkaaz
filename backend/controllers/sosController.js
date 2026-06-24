const SosAlert = require('../models/SosAlert');
const Application = require('../models/Application');
const { notifyAdmins, createNotification } = require('../utils/notification');

// @desc    Worker triggers SOS — saves to DB & notifies admin & active recruiters
// @route   POST /api/sos
// @access  Protected (worker)
exports.triggerSOS = async (req, res) => {
  try {
    const { lat, lng, address } = req.body;

    const alert = await SosAlert.create({
      workerId: req.user._id,
      workerName: req.user.name,
      workerPhone: req.user.phone,
      lat,
      lng,
      address: address || null,
    });

    const io = req.app.get('io');
    const title = `🆘 SOS Alert: ${req.user.name}`;
    const message = `Emergency triggered by worker. Phone: +91 ${req.user.phone}`;

    // 1. Notify Admins via standard notification pipeline (socket + FCM)
    await notifyAdmins({
      title,
      message,
      type: 'sos',
      relatedId: alert._id,
      io
    });

    // 2. Find active recruiters for this worker and notify them
    // An active recruiter is someone whose job application for this worker is 'accepted'
    const activeApps = await Application.find({
      workerId: req.user._id,
      status: 'accepted'
    }).populate('jobId', 'recruiterId');

    const notifiedRecruiterIds = new Set();
    
    for (const app of activeApps) {
      if (app.jobId && app.jobId.recruiterId) {
        const rId = app.jobId.recruiterId.toString();
        if (!notifiedRecruiterIds.has(rId)) {
          notifiedRecruiterIds.add(rId);
          await createNotification({
            userId: rId,
            title,
            message,
            type: 'sos',
            relatedId: alert._id,
            io
          });
        }
      }
    }

    res.status(201).json({ success: true, message: 'SOS alert sent securely to Admins and assigned Recruiters', data: alert });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Admin — get all SOS alerts
// @route   GET /api/admin/sos
// @access  Protected (admin)
exports.getAllSosAlerts = async (req, res) => {
  try {
    const alerts = await SosAlert.find()
      .populate('workerId', 'name phone profileImage')
      .sort({ createdAt: -1 });

    res.json({ success: true, data: alerts });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Admin — update SOS alert status
// @route   PATCH /api/admin/sos/:id
// @access  Protected (admin)
exports.updateSosStatus = async (req, res) => {
  try {
    const { status, adminNote } = req.body;

    const alert = await SosAlert.findByIdAndUpdate(
      req.params.id,
      {
        status,
        adminNote,
        acknowledgedBy: req.user._id,
      },
      { new: true }
    ).populate('workerId', 'name phone profileImage');

    if (!alert) {
      return res.status(404).json({ success: false, message: 'SOS alert not found' });
    }

    // Send notification to the worker
    const io = req.app.get('io');
    const noteText = adminNote ? ` Note: ${adminNote}` : ' The issue has been acknowledged and solved.';
    await createNotification({
      userId: alert.workerId._id,
      title: 'Kaamkaaz Team - SOS Update',
      message: `Your SOS alert is now marked as ${status}.${noteText}`,
      type: 'sos_update',
      relatedId: alert._id,
      io
    });

    res.json({ success: true, message: 'SOS alert updated', data: alert });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

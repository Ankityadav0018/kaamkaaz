const Report = require('../models/Report');
const { createNotification } = require('../utils/notification');
const User = require('../models/User');

// @desc    Submit a new report
// @route   POST /api/reports
exports.submitReport = async (req, res) => {
  try {
    const { title, description, screenshot, jobId, reportedUserId, jobTitle, workerName, recruiterName, reason } = req.body;

    if (!title || !description) {
      return res.status(400).json({ success: false, message: 'Title and description are required' });
    }

    const report = await Report.create({
      userId: req.user ? req.user.id : null,
      jobId,
      reportedUserId,
      jobTitle,
      workerName,
      recruiterName,
      reason,
      title,
      description,
      screenshot
    });

    // Notify Admins
    const admins = await User.find({ role: 'admin' });
    const io = req.app.get('io');
    const reporterName = req.user ? req.user.name : 'Anonymous User';

    for (const admin of admins) {
      await createNotification({
        userId: admin._id,
        title: '⚠️ New Bug Report',
        message: `${reporterName} reported a problem: ${title}`,
        type: 'bug_report',
        relatedId: report._id,
        io
      });
    }

    res.status(201).json({ success: true, message: 'Report submitted successfully. We will look into it!', data: report });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get all reports (Admin)
// @route   GET /api/reports
exports.getReports = async (req, res) => {
  try {
    const reports = await Report.find()
      .populate('userId', 'name phone email role')
      .populate('reportedUserId', 'name phone email role')
      .populate('jobId')
      .sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: reports.length, data: reports });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Update report status (Admin)
// @route   PUT /api/reports/:id
exports.updateReportStatus = async (req, res) => {
  try {
    const { status, adminNote } = req.body;
    const report = await Report.findById(req.params.id);

    if (!report) return res.status(404).json({ success: false, message: 'Report not found' });

    report.status = status || report.status;
    report.adminNote = adminNote || report.adminNote;
    await report.save();

    // Notify User
    if (status) {
      await createNotification({
        userId: report.userId,
        title: 'Update on your Bug Report',
        message: `Your report "${report.title}" is now marked as: ${status}`,
        type: 'report_update',
        relatedId: report._id,
        io: req.app.get('io')
      });
    }

    res.status(200).json({ success: true, message: 'Report updated', data: report });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

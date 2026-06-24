const Dispute = require('../models/Dispute');
const Job = require('../models/Job');
const User = require('../models/User');
const { createNotification } = require('../utils/notification');

// @desc    Raise a new dispute
// @route   POST /api/disputes
// @access  Worker or Recruiter
exports.raiseDispute = async (req, res) => {
  try {
    const { jobId, category, description } = req.body;

    const job = await Job.findById(jobId);
    if (!job) {
      return res.status(404).json({ success: false, message: 'Job not found' });
    }

    // Validate: job must be completed
    if (job.status !== 'completed') {
      return res.status(400).json({ success: false, message: 'Disputes can only be raised for completed jobs' });
    }

    // Validate: no existing dispute
    if (job.hasDispute) {
      return res.status(400).json({ success: false, message: 'A dispute has already been raised for this job' });
    }

    // Validate: within 24 hours of completion
    const completedAt = job.updatedAt; // assuming status 'completed' was set at the last update
    const diffHours = (new Date() - completedAt) / (1000 * 60 * 60);
    if (diffHours > 24) {
      return res.status(400).json({ success: false, message: 'Disputes can only be raised within 24 hours of job completion' });
    }

    // Determine roles and against user
    let raisedByRole = req.user.role;
    let againstUserId;

    if (raisedByRole === 'worker') {
      againstUserId = job.recruiterId;
    } else if (raisedByRole === 'recruiter') {
      againstUserId = job.assignedWorkerId;
    } else {
       return res.status(403).json({ success: false, message: 'Only workers or recruiters can raise disputes' });
    }

    if (!againstUserId) {
        return res.status(400).json({ success: false, message: 'Cannot raise dispute: No counterparty found' });
    }

    const dispute = await Dispute.create({
      jobId,
      raisedBy: req.user.id,
      raisedByRole,
      againstUserId,
      category,
      description
    });

    // Update job
    job.hasDispute = true;
    job.disputeRaisedAt = new Date();
    await job.save();

    // Notify admin (via socket or specialized notification logic)
    const io = req.app.get('io');
    const admins = await User.find({ role: 'admin' }).select('_id');
    for (const admin of admins) {
      await createNotification({
        userId: admin._id,
        title: 'New Dispute Raised',
        message: `Dispute for job: ${job.title} by ${req.user.name}`,
        type: 'dispute_pending',
        relatedId: dispute._id,
        io
      });
    }

    res.status(201).json({ success: true, data: dispute });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get user's own disputes
// @route   GET /api/disputes/my
// @access  Worker or Recruiter
exports.getMyDisputes = async (req, res) => {
  try {
    const disputes = await Dispute.find({ raisedBy: req.user.id })
      .populate('jobId', 'title category')
      .populate('againstUserId', 'name')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, data: disputes });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Admin: Get all disputes
// @route   GET /api/admin/disputes
// @access  Admin
exports.adminGetDisputes = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const query = status ? { status } : {};

    const disputes = await Dispute.find(query)
      .populate('jobId', 'title category wage wageType')
      .populate('raisedBy', 'name role phone')
      .populate('againstUserId', 'name role phone')
      .sort({ createdAt: 1 }) // oldest first for admin to handle
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    const total = await Dispute.countDocuments(query);

    res.status(200).json({ success: true, total, data: disputes });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Admin: Resolve or dismiss dispute
// @route   PATCH /api/admin/disputes/:id
// @access  Admin
exports.adminUpdateDispute = async (req, res) => {
  try {
    const { status, adminNote } = req.body;
    if (!['under_review', 'resolved', 'dismissed'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const dispute = await Dispute.findById(req.params.id);
    if (!dispute) return res.status(404).json({ success: false, message: 'Dispute not found' });

    dispute.status = status;
    dispute.adminNote = adminNote;
    
    if (status === 'resolved' || status === 'dismissed') {
      dispute.resolvedAt = new Date();
      dispute.resolvedBy = req.user.id;
    }

    await dispute.save();

    // Send notifications to both parties
    const io = req.app.get('io');
    const job = await Job.findById(dispute.jobId).select('title');
    
    const notificationPayload = {
      title: `Dispute ${status.toUpperCase()}`,
      message: `Your dispute for job "${job.title}" has been ${status}. Note: ${adminNote}`,
      type: 'kyc_update',
      relatedId: dispute._id,
      io
    };

    // Notify the raiser
    await createNotification({ ...notificationPayload, userId: dispute.raisedBy });
    // Notify the other party
    await createNotification({ ...notificationPayload, userId: dispute.againstUserId });

    res.status(200).json({ success: true, data: dispute });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Admin: Get dispute stats
// @route   GET /api/admin/disputes/stats
// @access  Admin
exports.getDisputeStats = async (req, res) => {
    try {
        const stats = await Dispute.aggregate([
            {
                $group: {
                    _id: "$status",
                    count: { $sum: 1 }
                }
            }
        ]);

        const result = {
            open: 0,
            under_review: 0,
            resolved: 0,
            dismissed: 0
        };

        stats.forEach(s => {
            if (result.hasOwnProperty(s._id)) {
                result[s._id] = s.count;
            }
        });

        res.status(200).json({ success: true, data: result });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

const User = require('../models/User');
const Job = require('../models/Job');
const Application = require('../models/Application');
const Transaction = require('../models/Transaction');
const Dispute = require('../models/Dispute');
const { createNotification } = require('../utils/notification');
const { JOB_CATEGORIES } = require('../utils/constants');
const NodeCache = require('node-cache');

const analyticsCache = new NodeCache({ stdTTL: 10 }); // 10 seconds cache for near real-time

// @desc    Get dashboard stats
// @route   GET /api/admin/stats
exports.getStats = async (req, res) => {
  try {
    const [workers, recruiters, jobs, applications, pendingKyc, pendingDriverKyc, verifiedDrivers] = await Promise.all([
      User.countDocuments({ role: 'worker' }),
      User.countDocuments({ role: 'recruiter' }),
      Job.countDocuments(),
      Application.countDocuments(),
      User.countDocuments({ kycStatus: 'pending' }),
      User.countDocuments({ workerType: 'driver', 'driverProfile.kycStatus': 'pending' }),
      User.countDocuments({ workerType: 'driver', 'driverProfile.kycStatus': 'verified' })
    ]);
    res.status(200).json({
      success: true,
      data: { 
        workers, recruiters, jobs, applications, 
        pendingKyc, pendingDriverKyc, verifiedDrivers,
        totalPendingKyc: pendingKyc + pendingDriverKyc 
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get all users (paginated)
// @route   GET /api/admin/users
exports.getAllUsers = async (req, res) => {
  try {
    const { role, kycStatus, page = 1, limit = 20, search } = req.query;
    const query = {};
    if (role) query.role = role;
    if (kycStatus) query.kycStatus = kycStatus;
    if (search) query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { phone: { $regex: search, $options: 'i' } }
    ];

    const total = await User.countDocuments(query);
    const users = await User.find(query)
      .select('-password -otp')
      .sort({ createdAt: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    res.status(200).json({ success: true, count: users.length, total, data: users });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get pending KYC users
// @route   GET /api/admin/kyc-pending
exports.getPendingKYC = async (req, res) => {
  try {

    const users = await User.find({ 
      role: 'worker',
      kycStatus: { $in: ['pending', 'submitted'] }
    }).select('-password -otp').sort({ createdAt: 1 });
    

    res.status(200).json({ success: true, count: users.length, data: users });
  } catch (err) {
    console.error('Error fetching pending workers:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Approve or reject KYC
// @route   PUT /api/admin/kyc/:userId
exports.reviewKYC = async (req, res) => {
  try {
    const { status, note } = req.body; // status: 'approved' | 'rejected'
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: req.t('validation.invalid_status') });
    }

    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    user.kycStatus = status;
    user.kycNote = note || '';

    if (user.workerType === 'driver') {
      if (!user.driverProfile) user.driverProfile = {};
      user.driverProfile.kycStatus = status === 'approved' ? 'verified' : 'rejected';
      user.driverProfile.kycRejectionReason = note || '';
      if (status === 'approved') user.driverProfile.kycVerifiedAt = new Date();
    }

    await user.save();

    const io = req.app.get('io');
    await createNotification({
      userId: user._id,
      title: status === 'approved' ? '✅ KYC Approved!' : '❌ KYC Rejected',
      message: status === 'approved'
        ? 'Your profile has been verified. You can now apply for jobs!'
        : `KYC rejected. Reason: ${note || 'Please resubmit with valid documents.'}`,
      type: status === 'approved' ? 'kyc_approved' : 'kyc_rejected',
      relatedId: user._id,
      io
    });

    res.status(200).json({ success: true, message: req.t('general.success'), data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Block / Unblock a user
// @route   PUT /api/admin/users/:userId/block
exports.toggleBlock = async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    if (user.role === 'admin') {
      return res.status(403).json({ success: false, message: req.t('auth.admin_cannot_be_blocked') });
    }

    user.isBlocked = !user.isBlocked;
    await user.save();

    res.status(200).json({
      success: true,
      message: req.t('general.success'),
      data: { isBlocked: user.isBlocked }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Warn a user
// @route   POST /api/admin/users/:userId/warn
exports.warnUser = async (req, res) => {
  try {
    const { reason } = req.body;
    const user = await User.findById(req.params.userId);
    
    if (!user) {
      return res.status(404).json({ success: false, message: req.t('general.not_found') });
    }

    // Send a warning notification
    const io = req.app.get('io');
    await createNotification({
      userId: user._id,
      title: '⚠️ Official Warning',
      message: `You have received a warning from the admin: ${reason || 'Violation of platform policies.'}`,
      type: 'account_warning',
      relatedId: user._id,
      io
    });

    res.status(200).json({
      success: true,
      message: 'Warning sent successfully'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get all jobs (admin)
// @route   GET /api/admin/jobs
exports.getAllJobs = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const query = status ? { status } : {};
    const total = await Job.countDocuments(query);
    const jobs = await Job.find(query)
      .populate('recruiterId', 'name phone companyName')
      .populate('assignedWorkerId', 'name phone')
      .sort({ createdAt: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));
    res.status(200).json({ success: true, count: jobs.length, total, data: jobs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get pending recruiters for verification
// @route   GET /api/admin/recruiters/pending
// @access  Admin
exports.getPendingRecruiters = async (req, res) => {
  try {
    const { status = 'pending' } = req.query;
    const recruiters = await User.find({ 
      role: 'recruiter', 
      'recruiterVerification.status': status 
    }).select('name phone recruiterVerification createdAt').sort({ 'recruiterVerification.kycSubmittedAt': 1 });

    res.status(200).json({
      success: true,
      count: recruiters.length,
      data: recruiters
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get single recruiter full details
// @route   GET /api/admin/recruiters/:userId
// @access  Admin
exports.getRecruiterDetails = async (req, res) => {
  try {
    const recruiter = await User.findById(req.params.userId).select('-password -otp');
    if (!recruiter || recruiter.role !== 'recruiter') {
      return res.status(404).json({ success: false, message: req.t('general.not_found') });
    }
    res.status(200).json({ success: true, data: recruiter });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Verify or suspend recruiter
// @route   PATCH /api/admin/recruiters/:userId/verify
// @access  Admin
exports.updateRecruiterVerification = async (req, res) => {
  try {
    const { action, reason } = req.body; // action: 'verify' | 'suspend'
    const recruiter = await User.findById(req.params.userId);

    if (!recruiter || recruiter.role !== 'recruiter') {
      return res.status(404).json({ success: false, message: req.t('general.not_found') });
    }

    if (action === 'verify') {
      recruiter.recruiterVerification.status = 'verified';
      recruiter.recruiterVerification.verifiedAt = new Date();
    } else if (action === 'suspend') {
      if (!reason || reason.length < 10) {
        return res.status(400).json({ success: false, message: req.t('validation.min_length', { count: 10 }) });
      }
      recruiter.recruiterVerification.status = 'suspended';
      recruiter.recruiterVerification.suspendedReason = reason;
    } else {
      return res.status(400).json({ success: false, message: req.t('general.bad_request') });
    }

    await recruiter.save();

    // FCM Notification
    const io = req.app.get('io');
    await createNotification({
      userId: recruiter._id,
      title: action === 'verify' ? '✅ Recruiter Approved!' : '🚫 Account Suspended',
      message: action === 'verify' 
        ? 'Your Kaamkaaz recruiter account is approved! You can now post jobs.'
        : `Your account has been suspended. Reason: ${reason}`,
      type: action === 'verify' ? 'recruiter_verified' : 'recruiter_suspended',
      relatedId: recruiter._id,
      io
    });

    res.status(200).json({
      success: true,
      message: req.t('general.success'),
      data: recruiter
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get complete analytics for dashboard
// @route   GET /api/admin/analytics
// @access  Admin
exports.getAnalytics = async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const parsedDays = parseInt(days, 10) || 30;
    const cacheKey = `admin_analytics_${parsedDays}`;
    const cachedData = analyticsCache.get(cacheKey);
    if (cachedData) {
      return res.status(200).json({ success: true, data: cachedData, cached: true });
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const weekAgo = new Date(today);
    weekAgo.setDate(today.getDate() - 7);
    
    // Set trend start date based on requested days
    const trendStartDate = new Date(today);
    trendStartDate.setDate(today.getDate() - parsedDays);

    const [
      overview,
      kyc,
      registrationTrend,
      jobsByCategoryRaw,
      topAreas,
      platformHealth
    ] = await Promise.all([
      // Overview
      (async () => {
        const [totalWorkers, totalRecruiters, totalJobs, jobsToday, jobsThisWeek, totalApps, appsToday, totalHires, activeDisputes, totalReferrals] = await Promise.all([
          User.countDocuments({ role: 'worker' }),
          User.countDocuments({ role: 'recruiter' }),
          Job.countDocuments(),
          Job.countDocuments({ createdAt: { $gte: today } }),
          Job.countDocuments({ createdAt: { $gte: weekAgo } }),
          Application.countDocuments(),
          Application.countDocuments({ createdAt: { $gte: today } }),
          Job.countDocuments({ status: 'completed' }),
          Dispute.countDocuments({ status: { $in: ['open', 'under_review'] } }),
          User.countDocuments({ referredBy: { $exists: true } })
        ]);
        return { totalWorkers, totalRecruiters, totalJobsPosted: totalJobs, jobsPostedToday: jobsToday, jobsPostedThisWeek: jobsThisWeek, totalApplications: totalApps, applicationsToday: appsToday, totalHires, activeDisputes, totalReferrals };
      })(),

      // KYC
      (async () => {
        const [pendingWorkers, pendingDrivers, pendingRecruiters, verifiedWorkers] = await Promise.all([
          User.countDocuments({ role: 'worker', kycStatus: 'pending' }),
          User.countDocuments({ role: 'worker', workerType: 'driver', 'driverProfile.kycStatus': 'pending' }),
          User.countDocuments({ role: 'recruiter', 'recruiterVerification.status': 'pending' }),
          User.countDocuments({ role: 'worker', kycStatus: 'approved' })
        ]);
        return { workersPendingKYC: pendingWorkers, driversPendingKYC: pendingDrivers, recruitersPendingVerification: pendingRecruiters, workersVerified: verifiedWorkers };
      })(),

      // Registration Trend (Dynamic days)
      User.aggregate([
        { $match: { createdAt: { $gte: trendStartDate }, role: { $in: ['worker', 'recruiter'] } } },
        {
          $group: {
            _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
            workers: { $sum: { $cond: [{ $eq: ["$role", "worker"] }, 1, 0] } },
            recruiters: { $sum: { $cond: [{ $eq: ["$role", "recruiter"] }, 1, 0] } }
          }
        },
        { $project: { date: "$_id", workers: 1, recruiters: 1, _id: 0 } },
        { $sort: { date: 1 } }
      ]),

      // Jobs by Category
      Job.aggregate([
        { $group: { _id: "$category", count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),

      // Top Areas
      Job.aggregate([
        { $group: { _id: "$location.village", jobCount: { $sum: 1 } } },
        { $sort: { jobCount: -1 } },
        { $limit: 5 },
        { $lookup: { from: 'users', let: { villageName: "$_id" }, pipeline: [{ $match: { $expr: { $eq: ["$village", "$$villageName"] }, role: 'worker' } }, { $count: "count" }], as: 'workers' } },
        { $project: { area: { $ifNull: ["$_id", "Unknown"] }, jobCount: 1, workerCount: { $ifNull: [{ $arrayElemAt: ["$workers.count", 0] }, 0] } } }
      ]),

      // Platform Health
      (async () => {
        const [jobsZeroApps, workersNeverApplied, totalJobs, totalApps, avgKycRes] = await Promise.all([
          Job.countDocuments({ applicantCount: 0 }),
          User.countDocuments({ role: 'worker', completedJobsCount: 0 }),
          Job.countDocuments(),
          Application.countDocuments(),
          // Avg KYC time (using updated vs created for approved users)
          User.aggregate([
            { $match: { kycStatus: 'approved', createdAt: { $exists: true }, updatedAt: { $exists: true } } },
            { $project: { duration: { $subtract: ["$updatedAt", "$createdAt"] } } },
            { $group: { _id: null, avgHours: { $avg: { $divide: ["$duration", 3600000] } } } }
          ])
        ]);
        return {
          jobsWithZeroApplicants: jobsZeroApps,
          workersNeverApplied,
          avgApplicationsPerJob: totalJobs > 0 ? (totalApps / totalJobs).toFixed(1) : 0,
          avgKYCApprovalHours: avgKycRes.length > 0 ? avgKycRes[0].avgHours.toFixed(1) : 0
        };
      })()
    ]);

    // Format jobsByCategory with emojis
    const jobsByCategory = jobsByCategoryRaw.map(j => {
      const cat = JOB_CATEGORIES.find(c => c.id === j._id) || { label: j._id || 'Other', emoji: '🔧' };
      return { category: cat.label, count: j.count, emoji: cat.emoji };
    });

    const finalData = { overview, kyc, registrationTrend, jobsByCategory, topAreas, platformHealth, updatedAt: new Date() };
    analyticsCache.set(cacheKey, finalData);

    res.status(200).json({ success: true, data: finalData });
  } catch (err) {
    console.error('Analytics Error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get all pending withdrawals
// @route   GET /api/admin/withdrawals/pending
// @access  Admin
exports.getPendingWithdrawals = async (req, res) => {
  try {
    const withdrawals = await Transaction.find({ type: 'withdrawal', status: 'pending' })
      .populate('userId', 'name phone role referralBalance')
      .sort({ createdAt: 1 });

    res.status(200).json({ success: true, count: withdrawals.length, data: withdrawals });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get withdrawal history
// @route   GET /api/admin/withdrawals/history
// @access  Admin
exports.getWithdrawalHistory = async (req, res) => {
  try {
    const withdrawals = await Transaction.find({ type: 'withdrawal' })
      .populate('userId', 'name phone role referralBalance')
      .sort({ updatedAt: -1 });

    res.status(200).json({ success: true, count: withdrawals.length, data: withdrawals });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Process a withdrawal (approve / reject)
// @route   POST /api/admin/withdrawals/:transactionId/process
// @access  Admin
exports.processWithdrawal = async (req, res) => {
  try {
    const { status, adminNote } = req.body; // status: 'completed' | 'rejected'
    if (!['completed', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const transaction = await Transaction.findById(req.params.transactionId);
    if (!transaction) {
      return res.status(404).json({ success: false, message: 'Transaction not found' });
    }

    if (transaction.status !== 'pending') {
      return res.status(400).json({ success: false, message: 'Transaction is already processed' });
    }

    // Save final status
    transaction.status = status;
    if (adminNote) {
      transaction.description = `${transaction.description || ''} (Admin Note: ${adminNote})`;
    }
    await transaction.save();

    // If rejected, refund the referral balance of the user
    if (status === 'rejected') {
      const user = await User.findById(transaction.userId);
      if (user) {
        user.referralBalance = (user.referralBalance || 0) + transaction.amount;
        await user.save();
      }
    }

    // Send push notification to user
    try {
      const user = await User.findById(transaction.userId);
      if (user) {
        const io = req.app.get('io');
        await createNotification({
          userId: user._id,
          title: status === 'completed' ? '✅ Withdrawal Success!' : '❌ Withdrawal Rejected',
          message: status === 'completed'
            ? `Your withdrawal request of ₹${transaction.amount} has been approved and completed.`
            : `Your withdrawal request of ₹${transaction.amount} was rejected. Note: ${adminNote || 'Refunded to referral earnings.'}`,
          type: status === 'completed' ? 'withdrawal_completed' : 'withdrawal_failed',
          relatedId: transaction._id,
          io
        });
      }
    } catch (notifyErr) {
      console.error('❌ Withdrawal response notification failed:', notifyErr.message);
    }

    res.status(200).json({ success: true, message: 'Processed successfully', data: transaction });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

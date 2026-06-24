const Application = require('../models/Application');
const Job = require('../models/Job');
const User = require('../models/User');
const { createNotification } = require('../utils/notification');

// @desc    Worker applies for a job
// @route   POST /api/applications
exports.applyForJob = async (req, res) => {
  try {
    const { jobId, message, preferredWage } = req.body;
    if (!jobId) return res.status(400).json({ success: false, message: req.t('validation.required_field') });

    const job = await Job.findById(jobId);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    if (job.status !== 'open') return res.status(400).json({ success: false, message: req.t('application.job_not_open') });

    // Check KYC
    if (req.user.kycStatus !== 'approved') {
      return res.status(403).json({ success: false, message: req.t('application.kyc_pending') });
    }

    const existing = await Application.findOne({ jobId, workerId: req.user.id });
    if (existing) return res.status(400).json({ success: false, message: req.t('application.already_applied') });

    const application = await Application.create({
      jobId, workerId: req.user.id, message: message || '', preferredWage: preferredWage || null
    });

    job.applicantCount += 1;
    await job.save();

    await createNotification({
      userId: job.recruiterId,
      title: 'New Application Received',
      message: `${req.user.name} applied for "${job.title}"`,
      type: 'job_application',
      relatedId: jobId,
      io: req.app.get('io')
    });

    res.status(201).json({ success: true, message: req.t('general.success'), data: application });
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ success: false, message: req.t('application.already_applied') });
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get all applications for a specific job (Recruiter)
// @route   GET /api/applications/job/:jobId
exports.getJobApplications = async (req, res) => {
  try {
    const job = await Job.findById(req.params.jobId);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    if (job.recruiterId.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: req.t('auth.unauthorized') });
    }

    const applications = await Application.find({ jobId: req.params.jobId })
      .populate('workerId', 'name skills rating location village profileImage completedJobsCount experienceDays')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: applications.length, data: applications });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get worker's own applications
// @route   GET /api/applications/my-applications
exports.getMyApplications = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const query = { workerId: req.user.id };
    if (status) query.status = status;

    const total = await Application.countDocuments(query);
    const applications = await Application.find(query)
      .populate({
        path: 'jobId',
        select: 'title description wage wageType location dateTime status category recruiterId',
        populate: { path: 'recruiterId', select: 'name companyName rating' }
      })
      .sort({ createdAt: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    res.status(200).json({ success: true, count: applications.length, total, data: applications });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Accept an application (Recruiter) — reveals contact
// @route   PUT /api/applications/:id/accept
exports.acceptApplication = async (req, res) => {
  try {
    const application = await Application.findById(req.params.id).populate('jobId');
    if (!application) return res.status(404).json({ success: false, message: 'Application not found' });

    const job = application.jobId;
    if (job.recruiterId.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: req.t('auth.unauthorized') });
    }
    if (application.status !== 'applied') {
      return res.status(400).json({ success: false, message: req.t('application.already_processed') });
    }

    // Accept & reveal contact
    application.status = 'accepted';
    application.respondedAt = new Date();
    application.contactRevealed = true;
    await application.save();

    // Fetch the total number of accepted workers for this job
    const acceptedCount = await Application.countDocuments({ jobId: job._id, status: 'accepted' });
    const limitReached = acceptedCount >= (job.maxWorkers || 1);

    // Update job worker assignment and status
    if (limitReached) {
      job.status = 'assigned';
    }
    job.assignedWorkerId = application.workerId;
    await job.save();

    // Reject other applicants only if we have reached the maxWorkers limit
    if (limitReached) {
      await Application.updateMany(
        { jobId: job._id, _id: { $ne: application._id }, status: 'applied' },
        { status: 'rejected', respondedAt: new Date() }
      );
    }

    const io = req.app.get('io');

    // Notify accepted worker
    await createNotification({
      userId: application.workerId,
      title: '🎉 You are Selected!',
      message: `Your application for "${job.title}" has been accepted!`,
      type: 'application_accepted',
      relatedId: job._id,
      io
    });

    // Get full worker profile (with phone) to send to recruiter
    const worker = await User.findById(application.workerId);

    res.status(200).json({
      success: true,
      message: req.t('general.success'),
      data: { application, worker: _workerFullProfile(worker) }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Reject an application
// @route   PUT /api/applications/:id/reject
exports.rejectApplication = async (req, res) => {
  try {
    const application = await Application.findById(req.params.id).populate('jobId');
    if (!application) return res.status(404).json({ success: false, message: 'Application not found' });
    if (application.jobId.recruiterId.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: req.t('auth.unauthorized') });
    }
    if (application.status !== 'applied') {
      return res.status(400).json({ success: false, message: req.t('application.already_processed') });
    }

    application.status = 'rejected';
    application.respondedAt = new Date();
    await application.save();

    await createNotification({
      userId: application.workerId,
      title: 'Application Update',
      message: `Your application for "${application.jobId.title}" was not selected.`,
      type: 'application_rejected',
      relatedId: application.jobId._id,
      io: req.app.get('io')
    });

    res.status(200).json({ success: true, message: req.t('general.success'), data: application });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Withdraw application (Worker)
// @route   DELETE /api/applications/:id
exports.withdrawApplication = async (req, res) => {
  try {
    const application = await Application.findById(req.params.id).populate('jobId');
    if (!application) return res.status(404).json({ success: false, message: 'Not found' });
    if (application.workerId.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: req.t('auth.unauthorized') });
    }
    if (application.status === 'accepted') {
      return res.status(400).json({ success: false, message: req.t('application.cannot_withdraw') });
    }

    if (application.jobId && application.jobId.applicantCount > 0) {
      application.jobId.applicantCount -= 1;
      await application.jobId.save();
    }

    await application.deleteOne();
    res.status(200).json({ success: true, message: req.t('general.deleted') });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get accepted worker full profile (Recruiter, after acceptance)
// @route   GET /api/applications/:id/worker-profile
exports.getWorkerProfile = async (req, res) => {
  try {
    const application = await Application.findById(req.params.id).populate('jobId');
    if (!application) return res.status(404).json({ success: false, message: 'Not found' });
    if (application.jobId.recruiterId.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: req.t('auth.unauthorized') });
    }
    if (application.status !== 'accepted') {
      return res.status(403).json({ success: false, message: req.t('application.contact_locked') });
    }

    const worker = await User.findById(application.workerId);
    res.status(200).json({ success: true, data: { ..._workerFullProfile(worker), jobId: application.jobId._id } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

const _workerFullProfile = (worker) => ({
  _id: worker._id,
  name: worker.name,
  phone: worker.phone, // Revealed after acceptance
  skills: worker.skills,
  village: worker.village,
  location: worker.location,
  profileImage: worker.profileImage,
  rating: worker.rating,
  completedJobsCount: worker.completedJobsCount,
  experienceDays: worker.experienceDays,
  createdAt: worker.createdAt
});

// @desc    Get all applications across all jobs for a recruiter
// @route   GET /api/applications/recruiter/all
// @access  Recruiter
exports.getRecruiterApplications = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    
    // First find all jobs belonging to recruiter
    const jobIds = await Job.find({ recruiterId: req.user.id }).distinct('_id');
    
    const query = { jobId: { $in: jobIds } };
    if (status) query.status = status;

    const total = await Application.countDocuments(query);
    const applications = await Application.find(query)
      .populate('jobId', 'title location status category')
      .populate('workerId', 'name profileImage skills rating village completedJobsCount')
      .sort({ createdAt: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    res.status(200).json({ success: true, count: applications.length, total, data: applications });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

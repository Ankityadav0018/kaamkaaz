const Job = require('../models/Job');
const Application = require('../models/Application');
const User = require('../models/User');
const { createNotification } = require('../utils/notification');
const mongoose = require('mongoose');

// @desc    Get recruiter stats
// @route   GET /api/recruiter/stats
// @access  Recruiter
exports.getRecruiterStats = async (req, res) => {
  try {
    const recruiterId = req.user.id;

    const stats = await Job.aggregate([
      { $match: { recruiterId: new mongoose.Types.ObjectId(recruiterId) } },
      {
        $group: {
          _id: null,
          totalJobsPosted: { $sum: 1 },
          activeJobs: {
            $sum: { $cond: [{ $in: ['$status', ['open', 'assigned']] }, 1, 0] }
          },
          totalCompleted: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          }
        }
      }
    ]);

    const hiredStats = await Application.countDocuments({
      status: { $in: ['accepted', 'completed'] },
      jobId: { $in: await Job.find({ recruiterId }).distinct('_id') }
    });

    const result = stats[0] || { totalJobsPosted: 0, activeJobs: 0, totalCompleted: 0 };
    result.totalHired = hiredStats;

    // Recruiter average rating received from workers
    const ratings = await Application.aggregate([
      {
        $match: {
          jobId: { $in: await Job.find({ recruiterId }).distinct('_id') },
          'recruiterRating.score': { $exists: true }
        }
      },
      {
        $group: {
          _id: null,
          avgRating: { $avg: '$recruiterRating.score' }
        }
      }
    ]);

    result.averageRatingReceived = ratings.length > 0 ? parseFloat(ratings[0].avgRating.toFixed(1)) : 0;

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get past workers previously hired
// @route   GET /api/recruiter/past-workers
// @access  Recruiter
exports.getPastWorkers = async (req, res) => {
  try {
    const recruiterId = new mongoose.Types.ObjectId(req.user.id);

    const pastWorkers = await Application.aggregate([
      { 
        $match: { 
          status: { $in: ['accepted', 'completed'] }
        } 
      },
      {
        $lookup: {
          from: 'jobs',
          localField: 'jobId',
          foreignField: '_id',
          as: 'job'
        }
      },
      { $unwind: '$job' },
      { $match: { 'job.recruiterId': recruiterId } },
      {
        $group: {
          _id: '$workerId',
          totalTimesHired: { $sum: 1 },
          lastHiredOn: { $max: '$createdAt' }
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'worker'
        }
      },
      { $unwind: '$worker' },
      {
        $project: {
          workerId: '$_id',
          name: '$worker.name',
          phone: '$worker.phone',
          rating: '$worker.rating.average',
          skills: '$worker.skills',
          kycStatus: '$worker.kycStatus',
          workerType: '$worker.workerType',
          completedJobsCount: '$worker.completedJobsCount',
          location: '$worker.location.address',
          lastHiredOn: 1,
          totalTimesHired: 1
        }
      },
      { $sort: { lastHiredOn: -1 } }
    ]);

    res.status(200).json({
      success: true,
      data: pastWorkers
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Re-invite a past worker to a new job
// @route   POST /api/recruiter/reinvite/:workerId
// @access  Recruiter
exports.reinviteWorker = async (req, res) => {
  try {
    const { jobId } = req.body;
    const { workerId } = req.params;
    const recruiterId = req.user.id;

    const job = await Job.findOne({ _id: jobId, recruiterId });
    if (!job) {
      return res.status(404).json({ success: false, message: 'Job not found or not authorized' });
    }

    const worker = await User.findById(workerId);
    if (!worker) {
      return res.status(404).json({ success: false, message: 'Worker not found' });
    }

    // Send notification
    await createNotification({
      userId: workerId,
      title: '📢 Job Invitation / न्योता',
      message: `${req.user.name} invites you to apply for ${job.title}`,
      type: 'invitation',
      relatedId: jobId,
      io: req.app.get('socketio')
    });

    res.status(200).json({
      success: true,
      message: 'Invitation sent successfully'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Submit recruiter onboarding verification
// @route   POST /api/recruiter/onboarding
// @access  Recruiter
exports.submitOnboarding = async (req, res) => {
  try {
    const { 
      businessType, businessName, areaOfOperation, purposeNote,
      aadhaarNumber, 
      aadhaarFrontUrl, aadhaarFrontPublicId,
      aadhaarBackUrl, aadhaarBackPublicId,
      selfieUrl, selfiePublicId 
    } = req.body;
    
    if (!businessType || !areaOfOperation || !aadhaarNumber || !aadhaarFrontUrl || !aadhaarBackUrl || !selfieUrl) {
      return res.status(400).json({ success: false, message: 'Please provide all required fields and documents' });
    }

    // Validate Aadhaar Number (exactly 12 digits)
    if (!/^\d{12}$/.test(aadhaarNumber)) {
      return res.status(400).json({ success: false, message: 'Aadhaar number must be exactly 12 digits' });
    }

    // Check uniqueness across ALL users (worker aadhaarNumber and recruiterVerification.aadhaarNumber)
    const existingAadhaar = await User.findOne({
      $or: [
        { aadhaarNumber: aadhaarNumber },
        { 'recruiterVerification.aadhaarNumber': aadhaarNumber }
      ],
      _id: { $ne: req.user.id }
    });

    if (existingAadhaar) {
      return res.status(400).json({ success: false, message: 'This Aadhaar number is already registered' });
    }

    const user = await User.findById(req.user.id);
    
    if (user.recruiterVerification.status === 'verified') {
      return res.status(400).json({ success: false, message: 'Account already verified' });
    }

    user.recruiterVerification = {
      status: 'pending',
      businessType,
      businessName,
      areaOfOperation,
      purposeNote,
      aadhaarNumber,
      aadhaarFrontUrl,
      aadhaarFrontPublicId,
      aadhaarBackUrl,
      aadhaarBackPublicId,
      selfieUrl,
      selfiePublicId,
      kycSubmittedAt: new Date()
    };

    await user.save();

    // Notify Admin of pending recruiter onboarding request
    try {
      const { notifyAdmins } = require('../utils/notification');
      await notifyAdmins({
        title: '🏢 New Recruiter Onboarding Request',
        message: `${user.name} has submitted recruiter onboarding verification documents.`,
        type: 'recruiter_onboarding_pending',
        relatedId: user._id,
        io: req.app.get('io')
      });
    } catch (notifyErr) {
      console.error('❌ Recruiter onboarding admin notification failed:', notifyErr.message);
    }

    res.status(200).json({
      success: true,
      message: 'Onboarding submitted successfully',
      data: user.recruiterVerification
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get recruiter verification status
// @route   GET /api/recruiter/verification-status
// @access  Recruiter
exports.getVerificationStatus = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('recruiterVerification');
    res.status(200).json({
      success: true,
      data: user.recruiterVerification
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

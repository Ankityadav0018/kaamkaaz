const Rating = require('../models/Rating');
const User = require('../models/User');
const Job = require('../models/Job');
const Application = require('../models/Application');

// @desc    Submit a rating
// @route   POST /api/ratings
exports.submitRating = async (req, res) => {
  try {
    const { jobId, score, comment } = req.body;
    if (!jobId || !score) return res.status(400).json({ success: false, message: req.t('validation.required_field') });
    if (score < 1 || score > 5) return res.status(400).json({ success: false, message: req.t('rating.score_range') });

    const job = await Job.findById(jobId);
    if (!job) return res.status(404).json({ success: false, message: req.t('general.not_found') });
    if (job.status !== 'completed') return res.status(400).json({ success: false, message: req.t('rating.job_not_completed') });

    let ratedUserId;
    let raterRole;

    if (req.user.role === 'worker') {
      // Worker rates recruiter
      if (job.assignedWorkerId?.toString() !== req.user.id) {
        return res.status(403).json({ success: false, message: req.t('rating.not_assigned') });
      }
      ratedUserId = job.recruiterId;
      raterRole = 'worker';
    } else if (req.user.role === 'recruiter') {
      // Recruiter rates worker
      if (job.recruiterId.toString() !== req.user.id) {
        return res.status(403).json({ success: false, message: req.t('auth.unauthorized') });
      }
      ratedUserId = job.assignedWorkerId;
      raterRole = 'recruiter';
    } else {
      return res.status(403).json({ success: false, message: req.t('rating.admin_no_rate') });
    }

    if (!ratedUserId) return res.status(400).json({ success: false, message: req.t('rating.no_user_to_rate') });

    const existing = await Rating.findOne({ jobId, raterId: req.user.id });
    if (existing) return res.status(400).json({ success: false, message: req.t('rating.already_rated') });

    const rating = await Rating.create({
      jobId, raterId: req.user.id, ratedUserId, raterRole, score, comment: comment || ''
    });

    // Update rated user's average
    const allRatings = await Rating.find({ ratedUserId });
    const avg = allRatings.reduce((sum, r) => sum + r.score, 0) / allRatings.length;
    await User.findByIdAndUpdate(ratedUserId, {
      'rating.average': parseFloat(avg.toFixed(1)),
      'rating.count': allRatings.length
    });

    // Update Application with rating info
    if (raterRole === 'recruiter') {
      await Application.findOneAndUpdate(
        { jobId, workerId: ratedUserId },
        { workerRating: { score, review: comment || '', createdAt: new Date() } }
      );
    } else if (raterRole === 'worker') {
      await Application.findOneAndUpdate(
        { jobId, workerId: req.user.id },
        { recruiterRating: { score, review: comment || '', createdAt: new Date() } }
      );
    }

    res.status(201).json({ success: true, message: req.t('general.success'), data: rating });
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ success: false, message: req.t('rating.already_rated') });
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get ratings for a user
// @route   GET /api/ratings/user/:userId
exports.getUserRatings = async (req, res) => {
  try {
    const ratings = await Rating.find({ ratedUserId: req.params.userId })
      .populate('raterId', 'name role')
      .populate('jobId', 'title')
      .sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: ratings.length, data: ratings });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

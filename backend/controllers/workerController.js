const Application = require('../models/Application');

const mongoose = require('mongoose');

// @desc    Get all applications by the worker
// @route   GET /api/worker/applications
// @access  Worker
exports.getWorkerApplications = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const query = { workerId: req.user.id };
    
    if (status) {
      query.status = status;
    }

    const applications = await Application.find(query)
      .populate({
        path: 'jobId',
        select: 'title category wage wageType location isUrgent status completedAt',
        populate: {
          path: 'recruiterId',
          select: 'name companyName'
        }
      })
      .sort({ createdAt: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    const total = await Application.countDocuments(query);

    res.status(200).json({
      success: true,
      total,
      data: applications
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get worker stats summary
// @route   GET /api/worker/stats
// @access  Worker
exports.getWorkerStats = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get counts for each status
    const stats = await Application.aggregate([
      { $match: { workerId: new mongoose.Types.ObjectId(userId) } },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    const result = {
      totalApplied: 0,
      totalAccepted: 0,
      totalCompleted: 0,
      totalRejected: 0,
      averageRating: 0,
      totalRatings: 0,
      memberSince: req.user.createdAt
    };

    stats.forEach(s => {
      result.totalApplied += s.count;
      if (s._id === 'accepted') result.totalAccepted = s.count;
      if (s._id === 'completed') result.totalCompleted = s.count;
      if (s._id === 'rejected') result.totalRejected = s.count;
    });

    // Calculate average rating from workerRating field in Application model
    const ratings = await Application.aggregate([
      { 
        $match: { 
          workerId: new mongoose.Types.ObjectId(userId),
          'workerRating.score': { $exists: true }
        } 
      },
      {
        $group: {
          _id: null,
          avgScore: { $avg: '$workerRating.score' },
          count: { $sum: 1 }
        }
      }
    ]);

    if (ratings.length > 0) {
      result.averageRating = parseFloat(ratings[0].avgScore.toFixed(1));
      result.totalRatings = ratings[0].count;
    }

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

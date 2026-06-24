const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema({
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
  raterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  ratedUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  raterRole: { type: String, enum: ['worker', 'recruiter'], required: true },
  score: { type: Number, required: true, min: 1, max: 5 },
  comment: { type: String, default: '', maxlength: 500 }
}, { timestamps: true });

// One rating per job per rater
ratingSchema.index({ jobId: 1, raterId: 1 }, { unique: true });

module.exports = mongoose.model('Rating', ratingSchema);

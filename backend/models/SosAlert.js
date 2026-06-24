const mongoose = require('mongoose');

const sosAlertSchema = new mongoose.Schema({
  workerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  workerName: { type: String },
  workerPhone: { type: String },
  lat: { type: Number },
  lng: { type: Number },
  address: { type: String },
  status: { type: String, enum: ['pending', 'acknowledged', 'resolved'], default: 'pending' },
  acknowledgedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  adminNote: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('SosAlert', sosAlertSchema);

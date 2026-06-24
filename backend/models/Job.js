const mongoose = require('mongoose');

const jobSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Job title is required'],
    trim: true,
    maxlength: [100, 'Title cannot exceed 100 characters']
  },
  description: {
    type: String,
    required: [true, 'Job description is required'],
    trim: true,
    maxlength: [1000, 'Description cannot exceed 1000 characters']
  },
  category: {
    type: String,
    enum: ['construction', 'farming', 'cleaning', 'painting', 'plumbing', 'electrical', 'carpentry', 'loading', 'cooking', 'driving', 'security', 'other'],
    default: 'other'
  },
  jobType: {
    type: String,
    enum: ['general', 'driver'],
    default: 'general'
  },
  driverRequirements: {
    vehicleType: String,
    mustHaveOwnVehicle: { type: Boolean, default: false },
    outstationRequired: { type: Boolean, default: false },
    licenseType: { type: String, default: null },           // MCWG, LMV, HMV, etc.
    minExperienceYears: { type: Number, default: 0, min: 0 },
    nightShift: { type: Boolean, default: false },
    fuelAllowance: { type: Boolean, default: false },
    tollAllowance: { type: Boolean, default: false },
    accommodation: { type: Boolean, default: false },
    uniformProvided: { type: Boolean, default: false },
    shiftTiming: { type: String, enum: ['day', 'night', 'flexible', null], default: null },
    tripType: { type: String, enum: ['local', 'intercity', 'outstation', null], default: null }
  },
  requiredSkills: [{ type: String, trim: true }],
  wage: { type: Number, required: true, min: 0 },
  wageType: { type: String, enum: ['hourly', 'daily', 'weekly', 'fixed'], default: 'daily' },
  maxWorkers: { type: Number, default: 1, min: 1 },
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], default: [0, 0] },
    address: { type: String, default: '' },
    village: { type: String, default: '' },
    district: { type: String, default: '' },
    state: { type: String, default: '' }
  },
  images: [{
    type: String
  }],
  dateTime: { type: Date, required: true },
  durationValue: { type: Number, default: 1 },
  durationUnit: { type: String, enum: ['hours', 'days', 'weeks', 'months'], default: 'days' },
  recruiterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  assignedWorkerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  status: {
    type: String,
    enum: ['open', 'assigned', 'completed', 'cancelled'],
    default: 'open'
  },
  applicantCount: { type: Number, default: 0, min: 0 },
  isUrgent: { type: Boolean, default: false },
  urgent_payment_id: { type: String, default: null },
  urgent_order_id: { type: String, default: null },
  urgent_payment_status: { type: String, enum: ['pending', 'success', 'failed', 'none'], default: 'none' },
  urgent_paid_at: { type: Date, default: null },
  urgent_fee_amount: { type: Number, default: 0 }, // in paise
  hasDispute: { type: Boolean, default: false },
  disputeRaisedAt: { type: Date, default: null },
  paymentStatus: {
    type: String,
    enum: ['unpaid', 'paid'],
    default: 'unpaid'
  },
  razorpayOrderId: String,
  razorpayPaymentId: String,
  isPublished: { type: Boolean, default: true }
}, { timestamps: true });

jobSchema.index({ location: '2dsphere' });
jobSchema.index({ status: 1, recruiterId: 1 });

module.exports = mongoose.model('Job', jobSchema);

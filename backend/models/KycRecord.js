const mongoose = require('mongoose');

const kycRecordSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true, 
    unique: true,
    index: true
  },
  
  // General Info
  documentType: { 
    type: String, 
    enum: ['Aadhaar', 'DrivingLicense', 'PAN', 'CompanyRegistration'], 
    default: 'Aadhaar'
  },
  documentNumber: { type: String, trim: true, sparse: true, unique: true },

  // Images
  frontImageUrl: { type: String, default: '' },
  frontImagePublicId: { type: String, default: '' },
  backImageUrl: { type: String, default: '' },
  backImagePublicId: { type: String, default: '' },
  selfieUrl: { type: String, default: '' },
  selfiePublicId: { type: String, default: '' },
  panImageUrl: { type: String, default: '' },
  panPublicId: { type: String, default: '' },

  // Additional Worker/Driver specific files
  rcBookUrl: { type: String, default: '' },
  rcBookPublicId: { type: String, default: '' },
  policeVerificationUrl: { type: String, default: '' },
  policeVerificationPublicId: { type: String, default: '' },
  passportPhotoUrl: { type: String, default: '' },
  passportPhotoPublicId: { type: String, default: '' },
  
  // Recruiter specific
  businessType: { 
    type: String, 
    enum: ['individual', 'contractor', 'factory', 'farm', 'company', 'household', 'other'] 
  },
  businessName: { type: String },
  areaOfOperation: { type: String },
  purposeNote: { type: String, maxlength: 500 },

  verificationState: { 
    type: String, 
    enum: ['not_submitted', 'pending', 'verified', 'rejected', 'suspended'], 
    default: 'not_submitted',
    index: true 
  },
  rejectionReason: { type: String, default: '' },
  
  submittedAt: { type: Date, default: null },
  verifiedAt: { type: Date, default: null },
  updatedAt: { type: Date, default: Date.now }
}, { timestamps: true });

kycRecordSchema.index({ verificationState: 1, submittedAt: 1 });

module.exports = mongoose.model('KycRecord', kycRecordSchema);

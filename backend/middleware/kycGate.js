const User = require('../models/User');
const AppError = require('../utils/AppError');
const errorMap = require('../utils/errorMap');

exports.requireKyc = async (req, res, next) => {
  try {
    if (req.user && req.user.role === 'admin') {
      return next(); // Admins bypass
    }

    if (!req.user || req.user.kycStatus !== 'approved') {
      return next(new AppError(
        errorMap.KYC_NOT_APPROVED.message,
        errorMap.KYC_NOT_APPROVED.statusCode,
        errorMap.KYC_NOT_APPROVED.errorCode
      ));
    }
    
    next();
  } catch (err) {
    next(err);
  }
};

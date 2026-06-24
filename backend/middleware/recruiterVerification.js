const User = require('../models/User');

exports.checkRecruiterVerification = async (req, res, next) => {
  if (req.user.role !== 'recruiter') return next();

  try {
    const user = await User.findById(req.user.id).select('recruiterVerification');
    
    if (user.recruiterVerification.status !== 'verified') {
      return res.status(403).json({
        success: false,
        message: 'Account pending verification or suspended',
        status: user.recruiterVerification.status
      });
    }
    
    next();
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error during verification check' });
  }
};

const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Protect routes
exports.protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }
  if (!token) {
    return res.status(401).json({ success: false, message: 'Not authorized, no token' });
  }
  try {
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      // Fallback: If token was signed as an Admin JWT, it will use ADMIN_JWT_SECRET
      const adminSecret = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET;
      decoded = jwt.verify(token, adminSecret);
    }
    
    req.user = await User.findById(decoded.id);
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }
    if (req.user.isBlocked) {
      return res.status(403).json({ success: false, message: 'Account is blocked. Contact admin.' });
    }
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Not authorized, token failed' });
  }
};

// Optional protect (allows both logged in and anonymous users)
exports.optionalProtect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) return next();

  try {
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      const adminSecret = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET;
      decoded = jwt.verify(token, adminSecret);
    }
    req.user = await User.findById(decoded.id);
  } catch (err) {
    // Ignore error for optional auth
  }
  next();
};

// Authorize specific roles
exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Role '${req.user.role}' is not authorized for this action`
      });
    }
    next();
  };
};

// Alias for authorize
exports.requireRole = exports.authorize;

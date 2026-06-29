/**
 * authSecurityController.js — Section 1.2 + 1.3
 * Refresh token rotation, logout, and password strength validation.
 * These are appended to the existing auth routes without touching authController.js.
 */

const jwt  = require('jsonwebtoken');
const User = require('../models/User');
const { blacklistToken, computeFingerprint } = require('../middleware/tokenAuth');
const { redisClient } = require('../config/redis');
const adminMailer = require('../services/adminMailer');

const ACCESS_SECRET  = process.env.ACCESS_TOKEN_SECRET  || process.env.JWT_SECRET;
const REFRESH_SECRET = process.env.REFRESH_TOKEN_SECRET || (process.env.JWT_SECRET + '_refresh');
const ACCESS_EXPIRE  = process.env.ACCESS_TOKEN_EXPIRE  || '15m';
const REFRESH_EXPIRE = process.env.REFRESH_TOKEN_EXPIRE || '7d';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Issue a fingerprint-bound access + refresh token pair */
exports.issueTokenPair = (user, req) => {
  const fp = computeFingerprint(req);
  const accessToken = jwt.sign(
    { id: user._id, role: user.role, fp, tv: user.tokenVersion || 0 },
    ACCESS_SECRET,
    { expiresIn: ACCESS_EXPIRE }
  );
  const refreshToken = jwt.sign(
    { id: user._id, tv: user.tokenVersion || 0 },
    REFRESH_SECRET,
    { expiresIn: REFRESH_EXPIRE }
  );
  return { accessToken, refreshToken };
};

/** Set httpOnly, secure, sameSite=strict refresh token cookie */
exports.setRefreshCookie = (res, token) => {
  res.cookie('kk_refresh', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    path: '/api/auth/refresh-token'
  });
};

/**
 * Validate password strength — Section 1.1
 * Returns an error string or null if valid.
 */
exports.validatePasswordStrength = (password) => {
  if (!password || password.length < 8) return 'Password must be at least 8 characters.';
  if (!/\d/.test(password)) return 'Password must contain at least one number.';
  if (!/[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/.test(password)) {
    return 'Password must contain at least one special character (!@#$%^&* etc.).';
  }
  return null;
};

// ─── Refresh Token Rotation ───────────────────────────────────────────────────

/**
 * @desc  Rotate refresh token + issue new access token
 * @route POST /api/auth/refresh-token
 * @access Public (httpOnly cookie required)
 */
exports.refreshToken = async (req, res) => {
  try {
    const oldToken = req.cookies?.kk_refresh;
    if (!oldToken) {
      return res.status(401).json({ success: false, message: 'No refresh token provided.' });
    }

    // ── Check blacklist FIRST — reused token = potential theft ────────────────
    const isBlacklisted = await redisClient.get(`blacklist:${oldToken}`);
    if (isBlacklisted) {
      try {
        const decoded = jwt.decode(oldToken);
        if (decoded?.id) {
          // Invalidate ALL existing sessions for this user
          await User.findByIdAndUpdate(decoded.id, { $inc: { tokenVersion: 1 } });
          const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '').split(',')[0].trim();
          adminMailer.sendRefreshTokenReuseAlert({
            to: process.env.ADMIN_ALERT_EMAIL || process.env.SMTP_USER || '',
            userId: decoded.id.toString(),
            ip
          }).catch(() => {});
        }
      } catch {}
      res.clearCookie('kk_refresh', { path: '/api/auth/refresh-token' });
      return res.status(401).json({
        success: false,
        message: 'Refresh token reuse detected. All sessions revoked for your safety. Please log in again.'
      });
    }

    // ── Verify refresh token ──────────────────────────────────────────────────
    let decoded;
    try {
      decoded = jwt.verify(oldToken, REFRESH_SECRET);
    } catch {
      return res.status(401).json({ success: false, message: 'Refresh token invalid or expired.' });
    }

    const user = await User.findById(decoded.id);
    if (!user || user.isBlocked) {
      return res.status(401).json({ success: false, message: 'Account not found or blocked.' });
    }

    // tokenVersion mismatch = password was reset — all old tokens invalid
    if (typeof decoded.tv === 'number' && decoded.tv !== user.tokenVersion) {
      return res.status(401).json({ success: false, message: 'Session invalidated by a password change. Please log in again.' });
    }

    // ── Rotate: immediately blacklist the consumed refresh token ──────────────
    const oldTtl = Math.max(decoded.exp - Math.floor(Date.now() / 1000), 1);
    await redisClient.setex(`blacklist:${oldToken}`, oldTtl, '1');

    // ── Issue fresh token pair ────────────────────────────────────────────────
    const { accessToken, refreshToken } = exports.issueTokenPair(user, req);
    exports.setRefreshCookie(res, refreshToken);

    return res.status(200).json({
      success: true,
      accessToken,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });

  } catch (err) {
    console.error('[refreshToken] Error:', err.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── Logout ───────────────────────────────────────────────────────────────────

/**
 * @desc  Logout — immediately blacklist both access and refresh tokens
 * @route POST /api/auth/logout
 * @access Private
 */
exports.logout = async (req, res) => {
  try {
    // Blacklist current access token
    const header = req.headers.authorization || '';
    const accessToken = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (accessToken) await blacklistToken(accessToken);

    // Blacklist refresh token from cookie
    const refreshToken = req.cookies?.kk_refresh;
    if (refreshToken) {
      try {
        const d = jwt.decode(refreshToken);
        const ttl = d?.exp ? Math.max(d.exp - Math.floor(Date.now() / 1000), 1) : 7 * 24 * 60 * 60;
        await redisClient.setex(`blacklist:${refreshToken}`, ttl, '1');
      } catch {}
    }

    res.clearCookie('kk_refresh', { path: '/api/auth/refresh-token' });
    return res.status(200).json({ success: true, message: 'Logged out successfully.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Logout failed.' });
  }
};

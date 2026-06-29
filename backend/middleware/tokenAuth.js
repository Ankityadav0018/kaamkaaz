/**
 * tokenAuth.js — Section 1.2: Hardened JWT Authentication
 *
 * Replaces the legacy `protect` middleware for all routes.
 * Enforces:
 *   1. Short-lived accessToken (15 min) verification.
 *   2. IP + User-Agent hash binding — if either changes, token is rejected.
 *   3. Redis blacklist check — logout / password-reset instantly revokes tokens.
 *   4. tokenVersion check — password reset invalidates ALL previous sessions.
 *
 * The legacy `protect` middleware in auth.js still works for backward compatibility
 * with routes that haven't been migrated yet.
 */

const jwt    = require('jsonwebtoken');
const crypto = require('crypto');
const User   = require('../models/User');
const { redisClient } = require('../config/redis');

const ACCESS_SECRET = process.env.ACCESS_TOKEN_SECRET || process.env.JWT_SECRET;

/** Compute a stable fingerprint from IP + User-Agent */
const computeFingerprint = (req) => {
  const ip = (req.headers['x-forwarded-for'] || '').split(',')[0].trim()
    || req.socket.remoteAddress
    || '';
  const ua = req.headers['user-agent'] || '';
  return crypto
    .createHash('sha256')
    .update(`${ip}:${ua}`)
    .digest('hex')
    .slice(0, 16); // first 16 hex chars is enough
};

/**
 * Full-strength protect middleware.
 * Usage: router.use(tokenAuth.protect);
 */
exports.protect = async (req, res, next) => {
  // ── 1. Extract token ────────────────────────────────────────────────────────
  const header = req.headers.authorization || '';
  const token  = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ success: false, message: 'Authentication required.' });
  }

  // ── 2. Verify signature + expiry ────────────────────────────────────────────
  let decoded;
  try {
    decoded = jwt.verify(token, ACCESS_SECRET);
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token invalid or expired.' });
  }

  // ── 3. Redis blacklist check ────────────────────────────────────────────────
  const isBlacklisted = await redisClient.get(`blacklist:${token}`);
  if (isBlacklisted) {
    return res.status(401).json({ success: false, message: 'Session has been revoked. Please log in again.' });
  }

  // ── 4. IP + UA fingerprint binding ─────────────────────────────────────────
  if (decoded.fp) {
    const currentFp = computeFingerprint(req);
    if (decoded.fp !== currentFp) {
      // Blacklist this token immediately — possible session hijack
      const ttl = Math.max(decoded.exp - Math.floor(Date.now() / 1000), 1);
      await redisClient.setex(`blacklist:${token}`, ttl, '1');
      return res.status(401).json({ success: false, message: 'Session fingerprint mismatch. Please log in again.' });
    }
  }

  // ── 5. Load user + tokenVersion check ──────────────────────────────────────
  const user = await User.findById(decoded.id);
  if (!user) {
    return res.status(401).json({ success: false, message: 'User not found.' });
  }
  if (user.isBlocked) {
    return res.status(403).json({ success: false, message: 'Account is blocked. Contact support.' });
  }
  // tokenVersion mismatch means password was reset → all old tokens invalid
  if (typeof decoded.tv === 'number' && decoded.tv !== user.tokenVersion) {
    return res.status(401).json({ success: false, message: 'Session invalidated. Please log in again.' });
  }

  req.user     = user;
  req.tokenRaw = token;
  next();
};

/**
 * Role-based access control middleware.
 * Usage: router.use(tokenAuth.authorize('admin', 'recruiter'))
 */
exports.authorize = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return res.status(403).json({
      success: false,
      message: `Access denied. Required role: ${roles.join(' or ')}.`
    });
  }
  next();
};

/**
 * Blacklist a token in Redis until its natural JWT expiry.
 * Call this on logout, password reset, and session revocation.
 */
exports.blacklistToken = async (token) => {
  try {
    const decoded = jwt.decode(token);
    const ttl = decoded?.exp
      ? Math.max(decoded.exp - Math.floor(Date.now() / 1000), 1)
      : 15 * 60;
    await redisClient.setex(`blacklist:${token}`, ttl, '1');
  } catch {
    // ignore — token already invalid
  }
};

/** Compute fingerprint — exported for use in auth controller */
exports.computeFingerprint = computeFingerprint;

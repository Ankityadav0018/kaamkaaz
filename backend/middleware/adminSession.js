/**
 * adminSession.js — Layer 5: Session Hardening
 *
 * Runs BEFORE anomaly detection and intent logging on every /api/admin/* route.
 * Enforces:
 *   1. Token must be a fully verified admin JWT (role: 'admin'), not admin_pending.
 *   2. IP binding — token must match the IP it was issued on.
 *   3. Token blacklist — instantly revokes stolen or logged-out tokens.
 *   4. Inactivity timeout — 30-minute rolling window; any activity resets the clock.
 */

const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { redisClient: redis } = require('../config/redis');

const ADMIN_SECRET     = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET;
const INACTIVITY_SEC   = 30 * 60; // 30 minutes

/** Extract real client IP (reverse-proxy aware) */
const getIp = (req) =>
  (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.socket.remoteAddress || '0.0.0.0';

/** Blacklist a token in Redis until its natural expiry */
const blacklistToken = async (token, decoded) => {
  const ttl = decoded?.exp
    ? Math.max(decoded.exp - Math.floor(Date.now() / 1000), 1)
    : INACTIVITY_SEC;
  await redis.setex(`admin:blacklist:${token}`, ttl, '1');
};

const adminSession = async (req, res, next) => {
  // ── 1. Extract Bearer token ───────────────────────────────────────────────
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    return res.status(401).json({ success: false, message: 'Admin authentication required.' });
  }

  // ── 2. Verify JWT signature and expiry ────────────────────────────────────
  let decoded;
  try {
    decoded = jwt.verify(token, ADMIN_SECRET);
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid or expired admin token.' });
  }

  // ── 3. Must be a fully promoted admin token, NOT admin_pending ────────────
  if (decoded.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Additional verification required. Complete the OTP step first.'
    });
  }

  // ── 4. Token blacklist check ──────────────────────────────────────────────
  const isBlacklisted = await redis.get(`admin:blacklist:${token}`);
  if (isBlacklisted) {
    return res.status(401).json({ success: false, message: 'Session has been revoked. Please log in again.' });
  }

  // ── 5. IP binding check ───────────────────────────────────────────────────
  const currentIp = getIp(req);
  if (decoded.issuedIp && decoded.issuedIp !== currentIp) {
    // Blacklist token immediately — IP changed mid-session
    await blacklistToken(token, decoded);
    console.warn(`[adminSession] IP mismatch for admin ${decoded.id}: issued=${decoded.issuedIp} current=${currentIp}`);
    return res.status(401).json({
      success: false,
      message: 'Session invalidated: IP address changed. Please log in again.'
    });
  }

  // ── 6. Inactivity timeout — rolling 30-minute window ─────────────────────
  const lastActiveKey = `admin:session:lastActive:${decoded.id}`;
  const lastActive = await redis.get(lastActiveKey);

  if (!lastActive) {
    // Key expired — session timed out due to inactivity
    await blacklistToken(token, decoded);
    return res.status(401).json({
      success: false,
      message: 'Session expired due to inactivity. Please log in again.'
    });
  }

  // ── 7. Load admin user ────────────────────────────────────────────────────
  const admin = await User.findById(decoded.id);
  if (!admin || admin.role !== 'admin' || admin.isBlocked) {
    await blacklistToken(token, decoded);
    return res.status(401).json({ success: false, message: 'Admin account not found or blocked.' });
  }

  // ── 8. Refresh inactivity timer on every active request ──────────────────
  await redis.setex(lastActiveKey, INACTIVITY_SEC, Date.now().toString());

  // Attach to request for downstream middleware
  req.user       = admin;
  req.adminToken = token;
  req.adminIp    = currentIp;

  next();
};

module.exports = adminSession;

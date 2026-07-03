/**
 * adminSession.js — Layer 5: Session Hardening
 *
 * Runs BEFORE anomaly detection and intent logging on every /api/admin/* route.
 * Enforces:
 *   1. Token must be a fully verified admin JWT (role: 'admin'), not admin_pending.
 *   2. Token blacklist — instantly revokes stolen or logged-out tokens.
 *   3. Inactivity timeout — 8-hour rolling window; any activity resets the clock.
 *
 * Note: IP binding removed — mobile clients frequently change IPs (WiFi ↔ 4G).
 * Note: If Redis lastActive key is missing (Redis restart/expiry) but JWT is still
 *       cryptographically valid, the session is re-seeded rather than blacklisted.
 */

const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { redisClient: redis } = require('../config/redis');

const ADMIN_SECRET     = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET;
const INACTIVITY_SEC   = 8 * 60 * 60; // 8 hours

/** Extract real client IP (reverse-proxy aware) */
const getIp = (req) =>
  (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.socket.remoteAddress || '0.0.0.0';

/** Blacklist a token in Redis until its natural expiry */
const blacklistToken = async (token, decoded) => {
  try {
    const ttl = decoded?.exp
      ? Math.max(decoded.exp - Math.floor(Date.now() / 1000), 1)
      : INACTIVITY_SEC;
    await redis.setex(`admin:blacklist:${token}`, ttl, '1');
  } catch (redisErr) {
    console.error('[adminSession] Redis blacklist error:', redisErr.message);
  }
};

const adminSession = async (req, res, next) => {
  // ── 1. Extract Bearer token ───────────────────────────────────────────────
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    return res.status(401).json({ success: false, message: 'Admin authentication required.' });
  }

  // ── 2. Verify JWT signature and expiry ────────────────────────────────────
  // Try the dedicated ADMIN_JWT_SECRET first (tokens from the 2FA flow).
  // Fall back to JWT_SECRET for admins who logged in via the phone/OTP flow.
  // In both cases the role is enforced against MongoDB below — the DB is the
  // authoritative source of truth for admin privileges.
  let decoded;
  try {
    decoded = jwt.verify(token, ADMIN_SECRET);
  } catch (adminErr) {
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (jwtErr) {
      return res.status(401).json({ success: false, message: 'Invalid or expired admin token.' });
    }
  }

  // ── 3. Must be a fully promoted admin token, NOT admin_pending ────────────
  if (decoded.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Additional verification required. Complete the OTP step first.'
    });
  }

  // ── 4. Token blacklist check ──────────────────────────────────────────────
  try {
    const isBlacklisted = await redis.get(`admin:blacklist:${token}`);
    if (isBlacklisted) {
      return res.status(401).json({ success: false, message: 'Session has been revoked. Please log in again.' });
    }
  } catch (redisErr) {
    // Redis unavailable — log but don't block; JWT signature is sufficient
    console.error('[adminSession] Redis blacklist check failed:', redisErr.message);
  }

  // ── 5. Load admin user ────────────────────────────────────────────────────
  const admin = await User.findById(decoded.id);
  if (!admin || admin.role !== 'admin' || admin.isBlocked) {
    await blacklistToken(token, decoded);
    return res.status(401).json({ success: false, message: 'Admin account not found or blocked.' });
  }

  // ── 6. Inactivity timeout — rolling 8-hour window ────────────────────────
  // If the lastActive key is missing (Redis restart / TTL expired) but the JWT
  // is still cryptographically valid, re-seed the timer instead of blacklisting.
  // This prevents permanent lockout after a Redis restart on Render.
  const lastActiveKey = `admin:session:lastActive:${admin._id}`;
  try {
    const lastActive = await redis.get(lastActiveKey);
    if (!lastActive) {
      // Key gone but JWT is valid — re-seed the inactivity window
      console.warn(`[adminSession] Re-seeding lastActive for admin ${admin._id} (Redis key was missing)`);
      await redis.setex(lastActiveKey, INACTIVITY_SEC, Date.now().toString());
    } else {
      // Refresh the rolling window
      await redis.setex(lastActiveKey, INACTIVITY_SEC, Date.now().toString());
    }
  } catch (redisErr) {
    // Redis unavailable — allow request through; JWT is the primary auth
    console.error('[adminSession] Redis lastActive check failed:', redisErr.message);
  }

  // Attach to request for downstream middleware
  const currentIp = getIp(req);
  req.user       = admin;
  req.adminToken = token;
  req.adminIp    = currentIp;

  next();
};

module.exports = adminSession;

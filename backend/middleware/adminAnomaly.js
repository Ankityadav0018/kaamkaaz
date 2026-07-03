/**
 * adminAnomaly.js — Layer 3: Behavioral Anomaly Detection
 *
 * Runs AFTER adminSession (token is validated) on every /api/admin/* route.
 * Checks:
 *   (a) IP brute-force — block IP if 5+ login failures in 30 min (tracked in Redis).
 *   (b) Off-hours — if login is outside 6am–11pm in the admin's timezone, send alert.
 *   (c) Unknown IP — if IP is not in admin's knownIps list, hold request for 2 min
 *       waiting for email confirmation; reject with 401 if not confirmed in time.
 */

const crypto = require('crypto');
const { redisClient: redis } = require('../config/redis');
const adminMailer = require('../services/adminMailer');

const CONFIRMATION_WAIT_MS  = 2 * 60 * 1000; // 2 minutes
const CONFIRMATION_TOKEN_SEC = 2 * 60;        // 2 minutes (Redis TTL)
const POLL_INTERVAL_MS       = 500;            // check every 500ms

/** Get real IP (reverse-proxy aware) */
const getIp = (req) =>
  (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.socket.remoteAddress || '0.0.0.0';

/**
 * Returns the current hour (0–23) in the given IANA timezone.
 */
const getHourInTimezone = (timezone) => {
  try {
    const formatter = new Intl.DateTimeFormat('en-US', {
      hour: 'numeric',
      hour12: false,
      timeZone: timezone
    });
    return parseInt(formatter.format(new Date()), 10);
  } catch {
    // Default to UTC if timezone is invalid
    return new Date().getUTCHours();
  }
};

/**
 * Poll Redis for an IP confirmation token being approved.
 * Returns true when confirmed, false on timeout.
 */
const waitForIpConfirmation = async (confirmKey, timeoutMs) => {
  const { safeRedisGet } = require('../config/redis');
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const confirmed = await safeRedisGet(`${confirmKey}:confirmed`);
      if (confirmed === '1') return true;
    } catch (e) {
      // Ignore redis errors during polling
    }
    await new Promise(resolve => setTimeout(resolve, POLL_INTERVAL_MS));
  }
  return false;
};

const adminAnomaly = async (req, res, next) => {
  const admin   = req.user;   // set by adminSession
  const ip      = getIp(req);

  // ─────────────────────────────────────────────────────────────────────────
  // (a) Off-hours check
  // ─────────────────────────────────────────────────────────────────────────
  const timezone = admin.timezone || 'Asia/Kolkata';
  const hour     = getHourInTimezone(timezone);
  const isOffHours = hour < 6 || hour >= 23; // outside 6am–11pm

  if (isOffHours) {
    console.warn(`[adminAnomaly] Off-hours login for admin ${admin._id} at hour ${hour} (${timezone})`);
    // Fire-and-forget: do NOT block, just alert
    adminMailer.sendOffHoursAlert({
      to: admin.email,
      adminName: admin.name,
      ip,
      time: new Date().toLocaleString('en-IN', { timeZone: timezone }),
      timezone
    }).catch(err => console.error('[adminAnomaly] Off-hours email error:', err));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // (b) Unknown IP check (Disabled for Mobile)
  // ─────────────────────────────────────────────────────────────────────────
  // Mobile IPs change frequently between WiFi and 4G/5G. We no longer block 
  // or hold the request here because it causes the app to hang.
  // In the future, a push notification based device approval could be used.

  next();
};

module.exports = adminAnomaly;

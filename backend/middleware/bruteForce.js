/**
 * bruteForce.js — Section 1.3: Login Brute Force Protection
 *
 * Middleware + helpers to track and block:
 *   (a) Per-IP failures — 5 attempts / 15 min → block IP 24 hours after 10
 *   (b) Per-account failures — 5 attempts → lock account 30 min, send email
 *
 * Integrate by calling these helpers inside the login route handler.
 */

const { redisClient } = require('../config/redis');
const User = require('../models/User');
const adminMailer = require('../services/adminMailer');

const IP_FAIL_WINDOW   = 15 * 60;    // 15 minutes
const IP_FAIL_LIMIT    = 5;          // fails per window before warning
const IP_BLOCK_LIMIT   = 10;         // total fails before 24h block
const IP_BLOCK_TTL     = 24 * 60 * 60; // 24 hours

const ACCT_FAIL_LIMIT  = 5;          // fails before account lock
const ACCT_LOCK_TTL    = 30 * 60;    // 30 minutes

const getIp = (req) =>
  (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.socket.remoteAddress || '0.0.0.0';

// ─── IP-level checks ──────────────────────────────────────────────────────────

/**
 * Check if IP is hard-blocked (10+ failures in 15 min window).
 * Call BEFORE password lookup.
 * Returns true if blocked.
 */
exports.isIpBlocked = async (req) => {
  const ip = getIp(req);
  const blocked = await redisClient.get(`bruteforce:ip_blocked:${ip}`);
  return !!blocked;
};

/**
 * Record a failed login attempt for an IP.
 * Auto-blocks IP for 24h after IP_BLOCK_LIMIT total failures.
 */
exports.recordIpFailure = async (req) => {
  const ip = getIp(req);
  const countKey = `bruteforce:ip_count:${ip}`;

  const count = await redisClient.incr(countKey);
  // Reset TTL on each failure to extend the window
  await redisClient.expire(countKey, IP_FAIL_WINDOW);

  if (count >= IP_BLOCK_LIMIT) {
    // Block IP for 24 hours
    await redisClient.setex(`bruteforce:ip_blocked:${ip}`, IP_BLOCK_TTL, '1');
    await redisClient.del(countKey);
    // Alert admin
    adminMailer.sendSecurityAlert({
      to: process.env.ADMIN_ALERT_EMAIL || process.env.SMTP_USER || '',
      subject: '🚨 IP Auto-Blocked — Kaamkaaz',
      body: `IP ${ip} has been auto-blocked for 24 hours after ${IP_BLOCK_LIMIT} failed login attempts.`
    }).catch(() => {});
    return { blocked: true };
  }
  return { blocked: false, count };
};

/** Clear IP failure count after a successful login. */
exports.clearIpFailures = async (req) => {
  const ip = getIp(req);
  await redisClient.del(`bruteforce:ip_count:${ip}`);
};

// ─── Account-level checks ─────────────────────────────────────────────────────

/**
 * Check if a specific account email is locked.
 * Returns { locked: false } or { locked: true, ttlSeconds }
 */
exports.isAccountLocked = async (email) => {
  const key = `bruteforce:acct_locked:${email.toLowerCase()}`;
  const locked = await redisClient.get(key);
  if (!locked) return { locked: false };
  const ttl = await redisClient.ttl(key);
  return { locked: true, ttlSeconds: ttl };
};

/**
 * Record a failed login attempt for an account.
 * Locks account for 30 min + sends email after ACCT_FAIL_LIMIT failures.
 */
exports.recordAccountFailure = async (email, userName) => {
  const countKey  = `bruteforce:acct_count:${email.toLowerCase()}`;
  const count = await redisClient.incr(countKey);
  await redisClient.expire(countKey, ACCT_LOCK_TTL);

  if (count >= ACCT_FAIL_LIMIT) {
    // Lock account
    await redisClient.setex(`bruteforce:acct_locked:${email.toLowerCase()}`, ACCT_LOCK_TTL, '1');
    await redisClient.del(countKey);

    // Fetch user email for notification
    const user = await User.findOne({ email: email.toLowerCase() });
    if (user?.email) {
      adminMailer.sendAccountLockEmail({
        to: user.email,
        name: user.name || 'User',
        lockMinutes: Math.ceil(ACCT_LOCK_TTL / 60)
      }).catch(() => {});
    }
    return { locked: true };
  }
  return { locked: false, count };
};

/** Clear account failure count after successful login. */
exports.clearAccountFailures = async (email) => {
  await redisClient.del(`bruteforce:acct_count:${email.toLowerCase()}`);
};

/**
 * rateLimiter.js — Section 5.3
 * Tiered rate limiting + slow-down for all route categories.
 * All stores backed by Redis for distributed deployments.
 */

const rateLimit  = require('express-rate-limit');
const slowDown   = require('express-slow-down');
const { RedisStore } = require('rate-limit-redis');
const { redisClient } = require('../config/redis');

// Workaround for express-rate-limit > 6.x to safely get IP without triggering the validation error
const getIp = (req) => {
  if (req.ip) return req.ip;
  return req.headers['x-forwarded-for'] || req.connection?.remoteAddress || 'unknown';
};

// ─── Shared Redis store factory ───────────────────────────────────────────────
const makeRedisStore = (prefix) => new RedisStore({
  sendCommand: async (...args) => {
    if (redisClient.status !== 'ready') throw new Error('Redis not ready for rate limiter');
    return redisClient.call(...args);
  },
  prefix: `rl:${prefix}:`,
});

// ─── 1. Global Limiter — 100 req / min per IP ────────────────────────────────
exports.globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  store: makeRedisStore('global'),
  passOnStoreError: true,
  message: { success: false, message: 'Too many requests from this IP. Please try again later.' }
});

// ─── 2. Auth Limiter — 5 req / 15 min per IP (login, register, reset) ────────
exports.authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  store: makeRedisStore('auth'),
  passOnStoreError: true,
  skipSuccessfulRequests: true, // Only count failures
  message: { success: false, message: 'Too many authentication attempts. Please try again in 15 minutes.' }
});

// ─── 3. Auth Slow-Down — starts slowing after 3rd attempt ────────────────────
exports.authSlowDown = slowDown({
  windowMs: 15 * 60 * 1000,
  delayAfter: 3,
  delayMs: (used) => (used - 3) * 500, // +500ms per extra request after 3rd
  store: makeRedisStore('slow'),
  passOnStoreError: true,
});

// ─── 4. Upload Limiter — 10 uploads / hour per user (or IP if unauthed) ──────
exports.uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  keyGenerator: (req) => req.user ? `user:${req.user.id}` : getIp(req),
  store: makeRedisStore('upload'),
  passOnStoreError: true,
  message: { success: false, message: 'Upload limit reached. Maximum 10 uploads per hour.' }
});

// ─── 5. Recruiter Job-Post Limiter — 20 posts / day per recruiter ─────────────
exports.recruiterJobPostLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000,
  max: 20,
  keyGenerator: (req) => req.user ? `rec_post:${req.user.id}` : getIp(req),
  store: makeRedisStore('rec_post'),
  passOnStoreError: true,
  message: { success: false, message: 'Daily job post limit reached (20 per day). Try again tomorrow.' }
});

// ─── 6. Recruiter Profile-View Limiter — 100 views / hour per recruiter ───────
exports.recruiterProfileViewLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 100,
  keyGenerator: (req) => req.user ? `rec_view:${req.user.id}` : getIp(req),
  store: makeRedisStore('rec_view'),
  passOnStoreError: true,
  message: { success: false, message: 'Profile view limit reached (100 per hour). Please slow down.' }
});

// ─── 7. API Limiter — 300 req / min per authenticated user ───────────────────
exports.apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  keyGenerator: (req) => req.user ? req.user.id.toString() : getIp(req),
  store: makeRedisStore('api'),
  passOnStoreError: true,
  message: { success: false, message: 'API rate limit exceeded.' }
});

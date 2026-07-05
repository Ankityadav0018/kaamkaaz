/**
 * rateLimiter.js — Section 5.3
 * Tiered rate limiting + slow-down for all route categories.
 * All stores backed by Redis for distributed deployments.
 * Refactored to lazily initialize RedisStore to prevent startup crashes.
 */

const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const { RedisStore } = require('rate-limit-redis');
const { redisClient } = require('../config/redis');

// Workaround for express-rate-limit > 6.x to safely get IP without triggering the validation error
const getIp = (req) => {
  if (req.ip) return req.ip;
  return req.headers['x-forwarded-for'] || req.connection?.remoteAddress || 'unknown';
};

/**
 * Creates a rate limiter that falls back to memory if Redis is not ready.
 * It will lazily instantiate the RedisStore ONLY when the Redis client says 'ready'.
 */
const createLazyLimiter = (options, prefix) => {
  let redisLimiterInstance = null;
  // Create a memory limiter immediately to handle early requests before Redis connects
  const memoryLimiterInstance = rateLimit({ ...options });

  return (req, res, next) => {
    if (redisClient.status === 'ready') {
      if (!redisLimiterInstance) {
        redisLimiterInstance = rateLimit({
          ...options,
          store: new RedisStore({
            sendCommand: (...args) => redisClient.call(...args),
            prefix: `rl:${prefix}:`,
          })
        });
      }
      return redisLimiterInstance(req, res, next);
    }
    
    // If Redis is reconnecting or hasn't started yet, fall back gracefully
    return memoryLimiterInstance(req, res, next);
  };
};

/**
 * Creates a slow down middleware that falls back to memory if Redis is not ready.
 */
const createLazySlowDown = (options, prefix) => {
  let redisSlowDownInstance = null;
  const memorySlowDownInstance = slowDown({ ...options });

  return (req, res, next) => {
    if (redisClient.status === 'ready') {
      if (!redisSlowDownInstance) {
        redisSlowDownInstance = slowDown({
          ...options,
          // express-slow-down > 1.x uses standard rate-limit stores
          store: new RedisStore({
            sendCommand: (...args) => redisClient.call(...args),
            prefix: `sd:${prefix}:`,
          })
        });
      }
      return redisSlowDownInstance(req, res, next);
    }
    return memorySlowDownInstance(req, res, next);
  };
};

// ─── 1. Global Limiter — 100 req / min per IP ────────────────────────────────
exports.globalLimiter = createLazyLimiter({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  passOnStoreError: true,
  message: { success: false, message: 'Too many requests from this IP. Please try again later.' }
}, 'global');

// ─── 2. Auth Limiter — 5 req / 15 min per IP (login, register, reset) ────────
exports.authLimiter = createLazyLimiter({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  passOnStoreError: true,
  skipSuccessfulRequests: true, // Only count failures
  message: { success: false, message: 'Too many authentication attempts. Please try again in 15 minutes.' }
}, 'auth');

// ─── 3. Auth Slow-Down — starts slowing after 3rd attempt ────────────────────
exports.authSlowDown = createLazySlowDown({
  windowMs: 15 * 60 * 1000,
  delayAfter: 3,
  delayMs: (used) => (used - 3) * 500, // +500ms per extra request after 3rd
}, 'auth');

// ─── 4. Upload Limiter — 10 uploads / hour per user (or IP if unauthed) ──────
exports.uploadLimiter = createLazyLimiter({
  windowMs: 60 * 60 * 1000,
  max: 10,
  keyGenerator: (req) => req.user ? `user:${req.user.id}` : getIp(req),
  passOnStoreError: true,
  message: { success: false, message: 'Upload limit reached. Maximum 10 uploads per hour.' }
}, 'upload');

// ─── 5. Recruiter Job-Post Limiter — 20 posts / day per recruiter ─────────────
exports.recruiterJobPostLimiter = createLazyLimiter({
  windowMs: 24 * 60 * 60 * 1000,
  max: 20,
  keyGenerator: (req) => req.user ? `rec_post:${req.user.id}` : getIp(req),
  passOnStoreError: true,
  message: { success: false, message: 'Daily job post limit reached (20 per day). Try again tomorrow.' }
}, 'rec_post');

// ─── 6. Recruiter Profile-View Limiter — 100 views / hour per recruiter ───────
exports.recruiterProfileViewLimiter = createLazyLimiter({
  windowMs: 60 * 60 * 1000,
  max: 100,
  keyGenerator: (req) => req.user ? `rec_view:${req.user.id}` : getIp(req),
  passOnStoreError: true,
  message: { success: false, message: 'Profile view limit reached (100 per hour). Please slow down.' }
}, 'rec_view');

// ─── 7. API Limiter — 300 req / min per authenticated user ───────────────────
exports.apiLimiter = createLazyLimiter({
  windowMs: 60 * 1000,
  max: 300,
  keyGenerator: (req) => req.user ? req.user.id.toString() : getIp(req),
  passOnStoreError: true,
  message: { success: false, message: 'API rate limit exceeded.' }
}, 'api');

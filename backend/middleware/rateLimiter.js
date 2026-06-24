const rateLimit = require('express-rate-limit');
const { RedisStore } = require('rate-limit-redis');
const { redisClient } = require('../config/redis');

// Public endpoints: 100 requests per minute per IP
exports.globalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, 
  standardHeaders: true,
  legacyHeaders: false,
  store: new RedisStore({
    sendCommand: (...args) => redisClient.call(...args),
  }),
  message: { success: false, message: 'Too many requests from this IP, please try again later.' }
});

// Authenticated/Heavy endpoints: 300 requests per minute per User
exports.apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 300,
  keyGenerator: (req) => {
    // Rate limit by User ID if authenticated, fallback to IP
    return req.user ? req.user.id.toString() : req.ip; 
  },
  store: new RedisStore({
    sendCommand: (...args) => redisClient.call(...args),
  }),
  message: { success: false, message: 'API rate limit exceeded for this user.' }
});

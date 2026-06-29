/**
 * securityMonitor.js — Section 7: 401/403 Monitoring + Auto-block
 *
 * Intercepts all outgoing 401/403 responses.
 * Tracks them per IP in Redis.
 * Auto-blocks IPs with 10+ errors in 5 minutes and emails admin.
 *
 * Usage in server.js (place AFTER all route handlers, BEFORE error handler):
 *   app.use(require('./middleware/securityMonitor'));
 */

const { redisClient } = require('../config/redis');
const mailer = require('../services/mailer');

const WINDOW_SEC   = 5 * 60;  // 5 minutes
const BLOCK_LIMIT  = 10;       // 401/403 per window before auto-block
const BLOCK_TTL    = 24 * 60 * 60; // 24 hours

const getIp = (req) =>
  (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.socket.remoteAddress || '0.0.0.0';

const securityMonitor = (req, res, next) => {
  // Intercept res.status() to observe the final status code
  const originalJson = res.json.bind(res);

  res.json = async function (body) {
    const statusCode = res.statusCode;

    if (statusCode === 401 || statusCode === 403) {
      const ip     = getIp(req);
      const userId = req.user?._id?.toString() || 'unauthenticated';
      const route  = req.originalUrl;
      const ts     = new Date().toISOString();

      // ── Log the failed auth attempt ────────────────────────────────────────
      const logKey   = `secmon:log:${ip}`;
      const countKey = `secmon:count:${ip}`;

      // Store a summary in a Redis list (capped at 50 entries per IP)
      const entry = JSON.stringify({ statusCode, route, userId, ts });
      redisClient.lpush(logKey, entry).catch(() => {});
      redisClient.ltrim(logKey, 0, 49).catch(() => {});
      redisClient.expire(logKey, WINDOW_SEC).catch(() => {});

      // Increment failure counter
      const count = await redisClient.incr(countKey).catch(() => 0);
      redisClient.expire(countKey, WINDOW_SEC).catch(() => {});

      // ── Auto-block after BLOCK_LIMIT failures ──────────────────────────────
      if (count === BLOCK_LIMIT) {
        await redisClient.setex(`secmon:blocked:${ip}`, BLOCK_TTL, '1').catch(() => {});
        mailer.sendSecurityAlert({
          to:      process.env.ADMIN_ALERT_EMAIL || process.env.SMTP_USER || '',
          subject: `🚨 IP Auto-Blocked: ${ip}`,
          body:    `IP <strong>${ip}</strong> triggered ${BLOCK_LIMIT}+ auth failures in 5 minutes and has been auto-blocked for 24 hours. Last route: ${route}`
        }).catch(() => {});
      }
    }

    return originalJson(body);
  };

  next();
};

module.exports = securityMonitor;

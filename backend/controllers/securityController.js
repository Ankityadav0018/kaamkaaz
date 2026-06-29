/**
 * securityController.js — Section 7: Security Dashboard
 *
 * Admin-only endpoint that shows:
 *   - Active admin sessions (from Redis)
 *   - Recent failed logins (401/403 logs per IP from security monitor)
 *   - Currently blocked IPs
 *   - Accounts locked by brute-force
 *
 * Route: GET /api/admin/security-dashboard
 * Access: Full admin guard (adminSession + adminAnomaly + adminIntent)
 */

const { redisClient } = require('../config/redis');
const User = require('../models/User');

exports.getSecurityDashboard = async (req, res) => {
  try {
    // ── 1. Active admin sessions ─────────────────────────────────────────────
    const sessionKeys = await redisClient.keys('admin:session:lastActive:*');
    const activeSessions = await Promise.all(
      sessionKeys.map(async (key) => {
        const adminId = key.split(':').pop();
        const lastActive = await redisClient.get(key);
        const ttl = await redisClient.ttl(key);
        return { adminId, lastActive, expiresInSeconds: ttl };
      })
    );

    // ── 2. Flagged / blocked IPs ─────────────────────────────────────────────
    const blockedIpKeys = await redisClient.keys('secmon:blocked:*');
    const blockedIps = await Promise.all(
      blockedIpKeys.map(async (key) => {
        const ip  = key.replace('secmon:blocked:', '');
        const ttl = await redisClient.ttl(key);
        return { ip, blockedForSeconds: ttl };
      })
    );

    // Also include brute-force blocked IPs
    const bfBlockedKeys = await redisClient.keys('bruteforce:ip_blocked:*');
    const bruteForceBlockedIps = await Promise.all(
      bfBlockedKeys.map(async (key) => {
        const ip  = key.replace('bruteforce:ip_blocked:', '');
        const ttl = await redisClient.ttl(key);
        return { ip, reason: 'brute_force', blockedForSeconds: ttl };
      })
    );

    // ── 3. Locked accounts ───────────────────────────────────────────────────
    const lockedAccountKeys = await redisClient.keys('bruteforce:acct_locked:*');
    const lockedAccounts = await Promise.all(
      lockedAccountKeys.map(async (key) => {
        const email = key.replace('bruteforce:acct_locked:', '');
        const ttl   = await redisClient.ttl(key);
        return { email, lockedForSeconds: ttl };
      })
    );

    // ── 4. Recent 401/403 events (last 20 across all IPs) ───────────────────
    const logKeys = await redisClient.keys('secmon:log:*');
    const recentEvents = [];
    for (const key of logKeys.slice(0, 10)) {
      const ip      = key.replace('secmon:log:', '');
      const entries = await redisClient.lrange(key, 0, 4); // last 5 per IP
      entries.forEach(e => {
        try {
          recentEvents.push({ ip, ...JSON.parse(e) });
        } catch {}
      });
    }
    // Sort newest first
    recentEvents.sort((a, b) => new Date(b.ts) - new Date(a.ts));

    // ── 5. Blocked users in DB ───────────────────────────────────────────────
    const blockedUsers = await User.find({ isBlocked: true })
      .select('name email phone role isBlocked createdAt')
      .limit(20)
      .lean();

    return res.status(200).json({
      success: true,
      data: {
        activeSessions,
        blockedIps:    [...blockedIps, ...bruteForceBlockedIps],
        lockedAccounts,
        recentAuthFailures: recentEvents.slice(0, 20),
        dbBlockedUsers: blockedUsers
      }
    });

  } catch (err) {
    console.error('[securityController] Error:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to load security dashboard.' });
  }
};

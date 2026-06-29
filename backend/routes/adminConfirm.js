/**
 * adminConfirm.js — IP Confirmation Route (Layer 3 support)
 *
 * The admin clicks the one-click link from the "Was this you?" email.
 * This handler marks the confirmation token as approved in Redis so that
 * the waiting adminAnomaly middleware can let the original request proceed.
 *
 * GET /api/admin/confirm-ip?token=<token>&adminId=<id>&ip=<ip>
 */

const express   = require('express');
const router    = express.Router();
const { redisClient: redis } = require('../config/redis');
const User      = require('../models/User');

router.get('/confirm-ip', async (req, res) => {
  const { token, adminId, ip } = req.query;

  if (!token || !adminId || !ip) {
    return res.status(400).send(`
      <html><body style="font-family:sans-serif;text-align:center;padding:40px">
        <h2 style="color:#dc2626">❌ Invalid confirmation link.</h2>
        <p>This link is missing required parameters. Please try logging in again.</p>
      </body></html>
    `);
  }

  const confirmKey = `admin:ip_confirm:${token}`;
  const state = await redis.get(confirmKey);

  if (!state) {
    return res.status(410).send(`
      <html><body style="font-family:sans-serif;text-align:center;padding:40px">
        <h2 style="color:#b45309">⏰ Confirmation link expired.</h2>
        <p>This link was only valid for 2 minutes. Please log in again.</p>
      </body></html>
    `);
  }

  if (state === '1') {
    return res.status(200).send(`
      <html><body style="font-family:sans-serif;text-align:center;padding:40px">
        <h2 style="color:#15803d">✅ Already confirmed.</h2>
        <p>This IP address has already been approved.</p>
      </body></html>
    `);
  }

  // Mark as confirmed so the waiting middleware can proceed
  await redis.setex(`${confirmKey}:confirmed`, 2 * 60, '1');

  // Add the IP to the admin's trusted list persistently
  try {
    await User.findByIdAndUpdate(adminId, {
      $addToSet: { knownIps: decodeURIComponent(ip) }
    });
  } catch (err) {
    console.error('[adminConfirm] Failed to persist IP:', err.message);
  }

  return res.status(200).send(`
    <html><body style="font-family:sans-serif;text-align:center;padding:40px;background:#f0fdf4">
      <div style="max-width:400px;margin:0 auto;background:white;padding:32px;border-radius:12px;box-shadow:0 4px 16px rgba(0,0,0,0.08)">
        <h2 style="color:#15803d">✅ Login Confirmed</h2>
        <p>The login attempt from <strong>${decodeURIComponent(ip)}</strong> has been approved.</p>
        <p>This IP address has been added to your trusted devices.</p>
        <p style="color:#6b7280;font-size:13px;margin-top:20px">You can close this window.</p>
      </div>
    </body></html>
  `);
});

module.exports = router;

/**
 * adminIntent.js — Layer 4: Intent Logging + Destructive Action Guard
 *
 * Runs AFTER adminSession and adminAnomaly on every /api/admin/* data route.
 * Enforces:
 *   1. `x-admin-intent` header must be present — describes what the admin is doing.
 *   2. Every call is logged to AdminAuditLog (MongoDB).
 *   3. For routes in DESTRUCTIVE_ROUTES: requires a second admin's JWT in
 *      `x-admin-co-approval` header. Both tokens must be valid and from DIFFERENT admins.
 */

const jwt   = require('jsonwebtoken');
const User  = require('../models/User');
const AdminAuditLog = require('../models/AdminAuditLog');

const ADMIN_SECRET = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET;

/**
 * Routes that require a second admin co-approval.
 * Format: { method, path } — path is matched as a prefix.
 */
const DESTRUCTIVE_ROUTES = [
  { method: 'DELETE', path: '/api/admin/users' },
  { method: 'POST',   path: '/api/admin/users/bulk' },
  { method: 'GET',    path: '/api/admin/users/export' },
  { method: 'DELETE', path: '/api/admin/jobs' },
  { method: 'DELETE', path: '/api/admin/disputes' },
  { method: 'POST',   path: '/api/admin/withdrawals' },
  { method: 'DELETE', path: '/api/admin/sos' },
];

/** Check if the current request matches any destructive route */
const isDestructiveRoute = (method, path) =>
  DESTRUCTIVE_ROUTES.some(
    r => r.method === method.toUpperCase() && path.startsWith(r.path)
  );

/** Write an audit log entry — fire-and-forget, never blocks the request */
const writeAuditLog = ({ adminId, coApproverId, intent, method, route, ip, success, failReason }) => {
  AdminAuditLog.create({ adminId, coApproverId, intent, method, route, ip, success, failReason })
    .catch(err => console.error('[adminIntent] Audit log write failed:', err.message));
};

const adminIntent = async (req, res, next) => {
  const admin  = req.user;        // set by adminSession
  const ip     = req.adminIp || req.socket?.remoteAddress || '0.0.0.0';
  const method = req.method;
  const route  = req.originalUrl;

  // ── 1. Require x-admin-intent header ─────────────────────────────────────
  const intent = (req.headers['x-admin-intent'] || '').trim();
  if (!intent) {
    writeAuditLog({
      adminId: admin._id, intent: '(missing)', method, route, ip,
      success: false, failReason: 'Missing x-admin-intent header'
    });
    return res.status(400).json({
      success: false,
      message: 'Missing required header: x-admin-intent. Describe your intended action.'
    });
  }

  // ── 2. Destructive route — co-approval required ───────────────────────────
  if (isDestructiveRoute(method, route)) {
    const coApprovalHeader = (req.headers['x-admin-co-approval'] || '').trim();

    if (!coApprovalHeader) {
      writeAuditLog({
        adminId: admin._id, intent, method, route, ip,
        success: false, failReason: 'Missing co-approval for destructive route'
      });
      return res.status(403).json({
        success: false,
        message: 'This is a destructive action and requires co-approval from a second admin. Provide x-admin-co-approval header.'
      });
    }

    // Validate co-approver token
    let coDecoded;
    try {
      coDecoded = jwt.verify(coApprovalHeader, ADMIN_SECRET);
    } catch {
      writeAuditLog({
        adminId: admin._id, intent, method, route, ip,
        success: false, failReason: 'Invalid co-approval token'
      });
      return res.status(403).json({ success: false, message: 'Co-approval token is invalid or expired.' });
    }

    // Co-approver must be a full admin (not pending)
    if (coDecoded.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Co-approval token is not a valid admin token.' });
    }

    // Co-approver must be a DIFFERENT admin
    if (coDecoded.id.toString() === admin._id.toString()) {
      writeAuditLog({
        adminId: admin._id, intent, method, route, ip,
        success: false, failReason: 'Self co-approval attempt'
      });
      return res.status(403).json({ success: false, message: 'Co-approval must come from a different admin account.' });
    }

    // Verify co-approver exists and is active
    const coAdmin = await User.findById(coDecoded.id);
    if (!coAdmin || coAdmin.role !== 'admin' || coAdmin.isBlocked) {
      return res.status(403).json({ success: false, message: 'Co-approver account is not valid.' });
    }

    // Co-approver token must not be blacklisted
    const { redisClient: redis } = require('../config/redis');
    const coBlacklisted = await redis.get(`admin:blacklist:${coApprovalHeader}`);
    if (coBlacklisted) {
      return res.status(403).json({ success: false, message: 'Co-approval token has been revoked.' });
    }

    // ── All checks passed — write success audit log with co-approver ─────────
    writeAuditLog({
      adminId: admin._id,
      coApproverId: coAdmin._id,
      intent, method, route, ip,
      success: true
    });

    req.coApprover = coAdmin;
    return next();
  }

  // ── 3. Normal (non-destructive) route — just log and continue ────────────
  writeAuditLog({ adminId: admin._id, intent, method, route, ip, success: true });

  next();
};

module.exports = adminIntent;

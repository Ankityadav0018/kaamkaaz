/**
 * mailer.js — Unified email service for ALL security-related emails.
 * Covers: OTP, lockouts, anomaly alerts, device notifications, token reuse, brute-force blocks.
 * Falls back to console.log when SMTP is not configured (dev/test friendly).
 */

const nodemailer = require('nodemailer');

let _transporter = null;

const getTransport = () => {
  if (_transporter) return _transporter;
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) return null;
  _transporter = nodemailer.createTransport({
    host:   process.env.SMTP_HOST,
    port:   parseInt(process.env.SMTP_PORT || '587', 10),
    secure: process.env.SMTP_PORT === '465',
    auth:   { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
  });
  return _transporter;
};

const send = async ({ to, subject, html }) => {
  const t = getTransport();
  if (!t) {
    console.log(`[Mailer] SMTP not configured — console fallback`);
    console.log(`  TO: ${to}  SUBJECT: ${subject}`);
    console.log(`  BODY: ${html.replace(/<[^>]+>/g, '').trim().slice(0, 200)}`);
    return;
  }
  await t.sendMail({ from: `"Kaamkaaz Security" <${process.env.SMTP_USER}>`, to, subject, html });
};

// ─── Admin: OTP ───────────────────────────────────────────────────────────────
exports.sendOtpEmail = ({ to, otp, adminName }) => send({
  to, subject: '🔐 Kaamkaaz Admin Login OTP',
  html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #e5e7eb;border-radius:8px"><h2 style="color:#1d4ed8">Admin Login OTP</h2><p>Hello <strong>${adminName}</strong>,</p><p>Your one-time code:</p><div style="font-size:36px;font-weight:bold;letter-spacing:8px;text-align:center;padding:16px">${otp}</div><p style="color:#6b7280;font-size:13px">Expires in <strong>5 minutes</strong>.</p></div>`
});

// ─── Admin: Off-hours anomaly ─────────────────────────────────────────────────
exports.sendOffHoursAlert = ({ to, adminName, ip, time, timezone }) => send({
  to, subject: '⚠️ Kaamkaaz Admin — Off-hours Login',
  html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #fde68a;border-radius:8px;background:#fffbeb"><h2 style="color:#b45309">Off-hours Login Alert</h2><p>Hello <strong>${adminName}</strong>,</p><ul><li><strong>Time:</strong> ${time} (${timezone})</li><li><strong>IP:</strong> ${ip}</li></ul></div>`
});

// ─── Admin: Unknown IP confirmation ──────────────────────────────────────────
exports.sendIpConfirmationEmail = ({ to, adminName, ip, confirmUrl }) => send({
  to, subject: '🔒 Kaamkaaz Admin — New Device Confirmation',
  html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #e5e7eb;border-radius:8px"><h2 style="color:#dc2626">New Device Detected</h2><p>Hello <strong>${adminName}</strong>,</p><p>New IP: <code>${ip}</code></p><a href="${confirmUrl}" style="display:inline-block;margin-top:12px;padding:12px 24px;background:#1d4ed8;color:white;text-decoration:none;border-radius:6px;font-weight:bold">✅ Yes, allow access</a><p style="color:#6b7280;font-size:13px;margin-top:16px">Link expires in 2 minutes.</p></div>`
});

// ─── Admin: OTP lockout ───────────────────────────────────────────────────────
exports.sendLockoutAlert = ({ to, adminName, lockMinutes }) => send({
  to, subject: '🚫 Kaamkaaz Admin Account Locked',
  html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #fecaca;border-radius:8px;background:#fef2f2"><h2 style="color:#dc2626">Admin Account Locked</h2><p>Hello <strong>${adminName}</strong>,</p><p>3 failed OTP attempts — account locked for <strong>${lockMinutes} minutes</strong>.</p></div>`
});

// ─── Section 1.3: User account locked due to brute-force ─────────────────────
exports.sendAccountLockEmail = ({ to, name, lockMinutes }) => send({
  to, subject: '🔒 Your Kaamkaaz Account is Temporarily Locked',
  html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #fecaca;border-radius:8px;background:#fef2f2"><h2 style="color:#dc2626">Account Temporarily Locked</h2><p>Hello <strong>${name}</strong>,</p><p>Multiple failed login attempts have locked your account for <strong>${lockMinutes} minutes</strong>.</p><p>If this wasn't you, reset your password immediately.</p></div>`
});

// ─── Section 1.2: Refresh token reuse detected ───────────────────────────────
exports.sendRefreshTokenReuseAlert = ({ to, userId, ip }) => send({
  to, subject: '🚨 ALERT: Possible Session Theft — Kaamkaaz',
  html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:2px solid #dc2626;border-radius:8px;background:#fef2f2"><h2 style="color:#dc2626">🚨 Refresh Token Reuse</h2><p>A used refresh token was resubmitted — possible session theft.</p><ul><li><strong>User ID:</strong> ${userId}</li><li><strong>IP:</strong> ${ip}</li></ul><p><strong>All sessions revoked automatically.</strong></p></div>`
});

// ─── Section 7: Generic admin security alert ─────────────────────────────────
exports.sendSecurityAlert = ({ to, subject, body }) => send({
  to, subject: subject || '🚨 Security Alert — Kaamkaaz',
  html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:2px solid #f59e0b;border-radius:8px;background:#fffbeb"><h2 style="color:#b45309">⚠️ Security Alert</h2><p>${body}</p></div>`
});

// ─── Section 3: New device login notification (workers/recruiters) ────────────
exports.sendNewDeviceAccessEmail = ({ to, name, ip, time }) => send({
  to, subject: '🔔 New Device Login — Kaamkaaz',
  html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #e5e7eb;border-radius:8px"><h2 style="color:#1d4ed8">New Device Login</h2><p>Hello <strong>${name}</strong>,</p><p>Your Kaamkaaz account was accessed from a new device:</p><ul><li><strong>IP:</strong> ${ip}</li><li><strong>Time:</strong> ${time}</li></ul><p>If this wasn't you, change your password immediately.</p></div>`
});

// ─── Section 4: Recruiter auto-suspended ─────────────────────────────────────
exports.sendRecruiterSuspendedAlert = ({ to, recruiterName, flagCount }) => send({
  to, subject: '🚨 Recruiter Auto-Suspended — Kaamkaaz',
  html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:2px solid #dc2626;border-radius:8px;background:#fef2f2"><h2 style="color:#dc2626">Recruiter Auto-Suspended</h2><p>Recruiter <strong>${recruiterName}</strong> has been auto-suspended after being flagged by ${flagCount} workers.</p><p>Please review their account in the admin dashboard.</p></div>`
});

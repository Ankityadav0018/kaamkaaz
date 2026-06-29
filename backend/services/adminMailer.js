const nodemailer = require('nodemailer');

/**
 * adminMailer — shared email transport for all admin security alerts.
 * Falls back to console.log if SMTP is not configured so the rest
 * of the system keeps working in development without an email server.
 */

let transporter = null;

const getTransporter = () => {
  if (transporter) return transporter;

  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
    return null; // SMTP not configured — emails will be logged to console
  }

  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    secure: process.env.SMTP_PORT === '465',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });

  return transporter;
};

/**
 * Send an email or fall back to a console log.
 */
const sendMail = async ({ to, subject, html }) => {
  const t = getTransporter();
  if (!t) {
    console.log(`[AdminMailer] (SMTP not configured — console fallback)`);
    console.log(`  TO: ${to}`);
    console.log(`  SUBJECT: ${subject}`);
    console.log(`  BODY: ${html.replace(/<[^>]+>/g, '')}`);
    return;
  }
  await t.sendMail({
    from: `"Kaamkaaz Security" <${process.env.SMTP_USER}>`,
    to,
    subject,
    html
  });
};

// ─── Email Templates ──────────────────────────────────────────────────────────

/**
 * Layer 2: Send email OTP to admin.
 */
exports.sendOtpEmail = async ({ to, otp, adminName }) => {
  await sendMail({
    to,
    subject: '🔐 Kaamkaaz Admin Login OTP',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #e5e7eb;border-radius:8px">
        <h2 style="color:#1d4ed8">Kaamkaaz Admin Login</h2>
        <p>Hello <strong>${adminName}</strong>,</p>
        <p>Your one-time login code is:</p>
        <div style="font-size:36px;font-weight:bold;letter-spacing:8px;color:#111;text-align:center;padding:16px 0">${otp}</div>
        <p style="color:#6b7280;font-size:13px">This code expires in <strong>5 minutes</strong>. Do not share it with anyone.</p>
        <hr style="border:none;border-top:1px solid #e5e7eb;margin:20px 0">
        <p style="color:#9ca3af;font-size:12px">If you did not attempt to log in, contact the secondary admin immediately.</p>
      </div>
    `
  });
};

/**
 * Layer 3: Notify admin of an off-hours login attempt.
 */
exports.sendOffHoursAlert = async ({ to, adminName, ip, time, timezone }) => {
  await sendMail({
    to,
    subject: '⚠️ Kaamkaaz Admin — Off-hours Login Detected',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #fde68a;border-radius:8px;background:#fffbeb">
        <h2 style="color:#b45309">⚠️ Off-hours Login Alert</h2>
        <p>Hello <strong>${adminName}</strong>,</p>
        <p>An admin login was detected at an unusual hour:</p>
        <ul>
          <li><strong>Time:</strong> ${time} (${timezone})</li>
          <li><strong>IP:</strong> ${ip}</li>
        </ul>
        <p>If this was you, no action is needed. If not, revoke all admin sessions immediately.</p>
      </div>
    `
  });
};

/**
 * Layer 3: Send "Was this you?" IP confirmation email.
 */
exports.sendIpConfirmationEmail = async ({ to, adminName, ip, confirmUrl }) => {
  await sendMail({
    to,
    subject: '🔒 Kaamkaaz Admin — New Device Login Confirmation',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #e5e7eb;border-radius:8px">
        <h2 style="color:#dc2626">New Device Detected</h2>
        <p>Hello <strong>${adminName}</strong>,</p>
        <p>Someone tried to access the Kaamkaaz admin panel from a new IP address:</p>
        <p style="font-family:monospace;background:#f3f4f6;padding:8px;border-radius:4px">${ip}</p>
        <p><strong>Was this you?</strong></p>
        <a href="${confirmUrl}" style="display:inline-block;margin-top:12px;padding:12px 24px;background:#1d4ed8;color:white;text-decoration:none;border-radius:6px;font-weight:bold">
          ✅ Yes, this was me — allow access
        </a>
        <p style="color:#6b7280;font-size:13px;margin-top:16px">This link expires in <strong>2 minutes</strong>. If you did not attempt this login, ignore this email — the request has already been blocked.</p>
      </div>
    `
  });
};

/**
 * Layer 2: Notify admin that their account has been locked.
 */
exports.sendLockoutAlert = async ({ to, adminName, lockMinutes }) => {
  await sendMail({
    to,
    subject: '🚫 Kaamkaaz Admin Account Temporarily Locked',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #fecaca;border-radius:8px;background:#fef2f2">
        <h2 style="color:#dc2626">Account Temporarily Locked</h2>
        <p>Hello <strong>${adminName}</strong>,</p>
        <p>Due to <strong>3 failed OTP attempts</strong>, your admin account has been locked for <strong>${lockMinutes} minutes</strong>.</p>
        <p>If this was not you, contact the secondary admin to perform an emergency session reset.</p>
      </div>
    `
  });
};

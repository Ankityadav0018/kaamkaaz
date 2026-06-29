
// ─── Section 1.3 + Section 7 — Brute Force + Monitoring ─────────────────────

/**
 * Section 1.3: Notify user their account has been temporarily locked due to failed logins.
 */
exports.sendAccountLockEmail = async ({ to, name, lockMinutes }) => {
  const nodemailer = require('nodemailer');
  // Re-use the shared sendMail via dynamic require to keep this appendable
  const { sendAccountLockEmail: _ } = module.exports;
  const t = (() => {
    if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) return null;
    return nodemailer.createTransport({ host: process.env.SMTP_HOST, port: parseInt(process.env.SMTP_PORT || '587', 10), secure: process.env.SMTP_PORT === '465', auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS } });
  })();
  const html = `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #fecaca;border-radius:8px;background:#fef2f2"><h2 style="color:#dc2626">Your Account is Temporarily Locked</h2><p>Hello <strong>${name}</strong>,</p><p>Due to multiple failed login attempts, your Kaamkaaz account has been temporarily locked for <strong>${lockMinutes} minutes</strong>.</p><p>If this was not you, please reset your password immediately after the lock expires.</p></div>`;
  if (!t) { console.log(`[Mailer] Account lock email to ${to}: ${html.replace(/<[^>]+>/g,'')}`); return; }
  await t.sendMail({ from: `"Kaamkaaz Security" <${process.env.SMTP_USER}>`, to, subject: '🔒 Kaamkaaz Account Temporarily Locked', html });
};

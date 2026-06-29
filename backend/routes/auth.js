const express = require('express');
const router = express.Router();
const { 
  register, login, getMe, 
  updateProfile, updateLocation, updateFcmToken, 
  updateKyc, deleteAccount, changePassword,
  supabaseVerify, supabaseResetPassword, resetPassword, checkPhone, checkEmail,
  addPortfolioItem, deletePortfolioItem, addEmail
} = require('../controllers/authController');
const { refreshToken, logout } = require('../controllers/authSecurityController');
const { protect } = require('../middleware/auth');
const { authLimiter, authSlowDown } = require('../middleware/rateLimiter');

// ── Public auth routes — rate-limited + slow-down ─────────────────────────────
router.post('/register',                authSlowDown, authLimiter, register);
router.post('/login',                   authSlowDown, authLimiter, login);
router.post('/check-phone',             checkPhone);
router.post('/check-email',             checkEmail);
router.post('/supabase-verify',         supabaseVerify);
router.post('/supabase-reset-password', authLimiter, supabaseResetPassword);
router.post('/reset-password',          authLimiter, resetPassword);

// ── Section 1.2 — Refresh token rotation + logout ────────────────────────────
router.post('/refresh-token', refreshToken);
router.post('/logout',        protect, logout);

// Intermediary page for deep linking
router.get('/app-redirect', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Redirecting to Kaamkaaz...</title>
      <style>
        body { font-family: -apple-system, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; background: #f4f4f9; margin: 0; }
        .card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); text-align: center; }
        h2 { color: #333; margin-bottom: 20px; }
        .btn { display: inline-block; padding: 14px 28px; background-color: #007bff; color: white; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; margin-top: 10px; }
      </style>
    </head>
    <body>
      <div class="card">
        <h2>Open Kaamkaaz App</h2>
        <p>Click the button below to continue setting your new password.</p>
        <a id="redirectBtn" href="io.supabase.kaamkaaz://login-callback" class="btn">Open App</a>
      </div>
      <script>
        const btn = document.getElementById('redirectBtn');
        btn.href = "io.supabase.kaamkaaz://login-callback" + window.location.hash;
        setTimeout(() => { window.location.href = btn.href; }, 500);
      </script>
    </body>
    </html>
  `);
});

// ── Protected routes ──────────────────────────────────────────────────────────
router.get('/me',                   protect, getMe);
router.put('/profile',              protect, updateProfile);
router.post('/add-email',           protect, addEmail);
router.put('/location',             protect, updateLocation);
router.put('/fcm-token',            protect, updateFcmToken);
router.put('/kyc',                  protect, updateKyc);
router.put('/change-password',      protect, changePassword);
router.post('/delete-account',      protect, deleteAccount);
router.post('/portfolio',           protect, addPortfolioItem);
router.delete('/portfolio/:itemId', protect, deletePortfolioItem);

module.exports = router;

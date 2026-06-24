const express = require('express');
const router = express.Router();
const { 
  register, login, getMe, 
  updateProfile, updateLocation, updateFcmToken, 
  updateKyc, deleteAccount, changePassword,
  supabaseVerify, supabaseResetPassword, resetPassword, checkPhone, checkEmail,
  addPortfolioItem, deletePortfolioItem, addEmail
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');


router.post('/register', register);
router.post('/login', login);
router.post('/check-phone', checkPhone);
router.post('/check-email', checkEmail);
router.post('/supabase-verify', supabaseVerify);
router.post('/supabase-reset-password', supabaseResetPassword);
router.post('/reset-password', resetPassword);

// Intermediary page for deep linking
router.get('/app-redirect', (req, res) => {
  // Grab the hash fragments (like #access_token=...) passed by Supabase
  // We need to pass them to the app using JS
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
        // Forward the URL hash containing the auth tokens to the app!
        const btn = document.getElementById('redirectBtn');
        btn.href = "io.supabase.kaamkaaz://login-callback" + window.location.hash;
        
        // Auto redirect attempt (may be blocked by browser, hence the button)
        setTimeout(() => {
          window.location.href = btn.href;
        }, 500);
      </script>
    </body>
    </html>
  `);
});

router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.post('/add-email', protect, addEmail);
router.put('/location', protect, updateLocation);
router.put('/fcm-token', protect, updateFcmToken);
router.put('/kyc', protect, updateKyc);
router.put('/change-password', protect, changePassword);
router.post('/delete-account', protect, deleteAccount);
router.post('/portfolio', protect, addPortfolioItem);
router.delete('/portfolio/:itemId', protect, deletePortfolioItem);

module.exports = router;

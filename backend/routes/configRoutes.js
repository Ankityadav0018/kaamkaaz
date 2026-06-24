const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');

router.get('/ai', protect, (req, res) => {
  // Returns the Gemini API key to authenticated users securely
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ success: false, message: 'AI Assistant is not configured on the server.' });
  }
  res.status(200).json({ success: true, apiKey });
});

module.exports = router;

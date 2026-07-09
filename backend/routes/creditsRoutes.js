const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  getCreditPacks,
  getCredits,
  getCreditHistory,
  initiatePurchase,
  verifyPurchase
} = require('../controllers/creditsController');

// Public — list available credit packs
router.get('/packs', getCreditPacks);

// Recruiter — credit balance and history
router.get('/', protect, authorize('recruiter'), getCredits);
router.get('/history', protect, authorize('recruiter'), getCreditHistory);

// Recruiter — purchase a defined credit pack
router.post('/purchase', protect, authorize('recruiter'), initiatePurchase);
router.post('/verify-purchase', protect, authorize('recruiter'), verifyPurchase);

module.exports = router;

const express = require('express');
const router = express.Router();
const {
  getMyCode,
  getStats,
  applyReferral,
  getTransactions,
  requestWithdrawal
} = require('../controllers/referralController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/my-code', getMyCode);
router.get('/stats', getStats);
router.post('/apply', applyReferral);
router.get('/transactions', getTransactions);
router.post('/withdraw', requestWithdrawal);

module.exports = router;

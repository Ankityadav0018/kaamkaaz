const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const { getWallet, getTransactionHistory, initiateTopup, verifyTopup } = require('../controllers/walletController');

router.get('/', protect, authorize('recruiter'), getWallet);
router.get('/history', protect, authorize('recruiter'), getTransactionHistory);
router.post('/topup', protect, authorize('recruiter'), initiateTopup);
router.post('/verify-topup', protect, authorize('recruiter'), verifyTopup);

module.exports = router;

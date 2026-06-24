const express = require('express');
const router = express.Router();
const { raiseDispute, getMyDisputes } = require('../controllers/disputeController');
const { protect, authorize } = require('../middleware/auth');

router.post('/', protect, authorize('worker', 'recruiter'), raiseDispute);
router.get('/my', protect, authorize('worker', 'recruiter'), getMyDisputes);

module.exports = router;

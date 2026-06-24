const express = require('express');
const router = express.Router();
const { submitRating, getUserRatings } = require('../controllers/ratingController');
const { protect } = require('../middleware/auth');

router.post('/', protect, submitRating);
router.get('/user/:userId', protect, getUserRatings);

module.exports = router;

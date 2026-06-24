const express = require('express');
const router = express.Router();
const { getChatHistory, getInbox } = require('../controllers/chatController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/inbox', getInbox);
router.get('/:jobId/:otherUserId', getChatHistory);

module.exports = router;

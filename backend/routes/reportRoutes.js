const express = require('express');
const router = express.Router();
const { submitReport, getReports, updateReportStatus } = require('../controllers/reportController');
const { protect, authorize, optionalProtect } = require('../middleware/auth');

router.post('/', optionalProtect, submitReport);
router.get('/', protect, authorize('admin'), getReports);
router.put('/:id', protect, authorize('admin'), updateReportStatus);

module.exports = router;

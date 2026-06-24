const express = require('express');
const router = express.Router();
const { getWorkerApplications, getWorkerStats } = require('../controllers/workerController');
const { protect, authorize } = require('../middleware/auth');

router.use(protect, authorize('worker'));

router.get('/applications', getWorkerApplications);
router.get('/stats', getWorkerStats);

module.exports = router;

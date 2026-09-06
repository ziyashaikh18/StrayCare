const express = require('express');
const { listApprovedPartners } = require('../controllers/adminController');
const { protect, requireRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect, requireRole('admin'));
router.get('/partners', listApprovedPartners);

module.exports = router;

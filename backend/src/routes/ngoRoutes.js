const express = require('express');
const { removePartnership } = require('../controllers/ngoController');
const { protect, requireRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect, requireRole('ngo'));
router.post('/remove-partnership', removePartnership);

module.exports = router;

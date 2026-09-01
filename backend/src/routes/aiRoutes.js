const express = require('express');
const { analyzeImage } = require('../controllers/aiController');
const { protect } = require('../middleware/authMiddleware');
const { handleReportImageUpload } = require('../middleware/uploadMiddleware');

const router = express.Router();

// All AI analysis routes require a logged-in user
router.use(protect);

// POST /api/ai/analyze (protected, multipart/form-data with 'image' field)
router.post('/analyze', handleReportImageUpload, analyzeImage);

module.exports = router;

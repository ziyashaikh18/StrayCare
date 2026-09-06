const express = require('express');
const { chat } = require('../controllers/chatController');
const { protect } = require('../middleware/authMiddleware');
const { handleReportImageUpload } = require('../middleware/uploadMiddleware');

const router = express.Router();

router.post('/', protect, handleReportImageUpload, chat);

module.exports = router;

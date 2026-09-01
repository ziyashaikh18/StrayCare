const express = require('express');
const {
  createReport,
  getMyReports,
  getReportById,
  updateReport,
  deleteReport,
} = require('../controllers/reportController');
const { protect } = require('../middleware/authMiddleware');
const { handleReportImageUpload } = require('../middleware/uploadMiddleware');

const router = express.Router();

// All report routes require a logged-in user.
router.use(protect);

router.post('/', handleReportImageUpload, createReport);
router.get('/', getMyReports);
router.get('/:id', getReportById);
router.put('/:id', updateReport);
router.delete('/:id', deleteReport);

module.exports = router;
const express = require('express');
const {
  createReport,
  getAllReports,
  getMyReports,
  getNearbyReports,
  getReportById,
  assignReport,
  updateReportStatus,
  updateReport,
  deleteReport,
} = require('../controllers/reportController');
const { protect, requireRole } = require('../middleware/authMiddleware');
const { handleReportImageUpload } = require('../middleware/uploadMiddleware');

const router = express.Router();

// All report routes require a logged-in user.
router.use(protect);

router.post('/', handleReportImageUpload, createReport);
router.get('/admin/all', requireRole('ngo', 'admin'), getAllReports);
router.get('/my', getMyReports);
router.get('/', getMyReports);
router.get('/nearby', getNearbyReports);
router.get('/:id', getReportById);
router.patch('/:id/assign', requireRole('ngo', 'admin'), assignReport);
router.patch('/:id/status', requireRole('ngo', 'admin'), updateReportStatus);
router.put('/:id', updateReport);
router.delete('/:id', deleteReport);

module.exports = router;
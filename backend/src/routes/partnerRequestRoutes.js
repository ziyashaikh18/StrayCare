const express = require('express');
const {
  createRequest,
  getMyStatus,
  listRequests,
  approveRequest,
  rejectRequest,
} = require('../controllers/partnerRequestController');
const { protect, requireRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);
router.post('/', createRequest);
router.get('/my-status', getMyStatus);
router.get('/', requireRole('admin'), listRequests);
router.patch('/:id/approve', requireRole('admin'), approveRequest);
router.patch('/:id/reject', requireRole('admin'), rejectRequest);

module.exports = router;

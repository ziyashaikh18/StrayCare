const express = require('express');
const {
  listMyNotifications,
  markAsRead,
  markAllAsRead,
} = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);
router.get('/', listMyNotifications);
router.patch('/read-all', markAllAsRead);
router.patch('/:id/read', markAsRead);

module.exports = router;
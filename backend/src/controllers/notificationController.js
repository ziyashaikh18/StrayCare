const Notification = require('../models/Notification');

const toResponse = (notification) => ({
  id: notification._id,
  type: notification.type,
  title: notification.title,
  message: notification.message,
  relatedReport: notification.relatedReport || null,
  relatedPartnerRequest: notification.relatedPartnerRequest || null,
  isRead: notification.isRead,
  createdAt: notification.createdAt,
});

const listMyNotifications = async (req, res, next) => {
  try {
    const notifications = await Notification.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50);
    res.json({ success: true, data: { notifications: notifications.map(toResponse) } });
  } catch (error) {
    next(error);
  }
};

const markAsRead = async (req, res, next) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { isRead: true },
      { new: true }
    );
    if (!notification) {
      const error = new Error('Notification not found');
      error.statusCode = 404;
      throw error;
    }
    res.json({ success: true, data: { notifications: [toResponse(notification)] } });
  } catch (error) {
    next(error);
  }
};

const markAllAsRead = async (req, res, next) => {
  try {
    await Notification.updateMany({ user: req.user._id, isRead: false }, { isRead: true });
    res.json({ success: true, data: { notifications: [] } });
  } catch (error) {
    next(error);
  }
};

module.exports = { listMyNotifications, markAsRead, markAllAsRead };
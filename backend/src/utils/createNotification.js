const Notification = require('../models/Notification');

const createNotification = async ({
  user,
  type,
  title,
  message,
  relatedReport,
  relatedPartnerRequest,
}) => Notification.create({
  user,
  type,
  title,
  message,
  relatedReport,
  relatedPartnerRequest,
});

module.exports = createNotification;
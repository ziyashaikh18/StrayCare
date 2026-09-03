const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: {
      type: String,
      enum: ['report_status_changed', 'report_assigned', 'partner_approved', 'partner_rejected'],
      required: true,
    },
    title: { type: String, required: true },
    message: { type: String, required: true },
    relatedReport: { type: mongoose.Schema.Types.ObjectId, ref: 'Report' },
    relatedPartnerRequest: { type: mongoose.Schema.Types.ObjectId, ref: 'PartnerRequest' },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);
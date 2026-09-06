const express = require('express');
const healthRoutes = require('./healthRoutes');
const testRoutes = require('./testRoutes');
const authRoutes = require('./authRoutes');
const reportRoutes = require('./reportRoutes');
const aiRoutes = require('./aiRoutes');   
const partnerRequestRoutes = require('./partnerRequestRoutes');
const notificationRoutes = require('./notificationRoutes');
const adminRoutes = require('./adminRoutes');
const ngoRoutes = require('./ngoRoutes');
const chatRoutes = require('./chatRoutes');
const router = express.Router();

// Mount sub-routes
router.use('/health', healthRoutes);
router.use('/test', testRoutes);
router.use('/auth', authRoutes);
router.use('/reports', reportRoutes);
router.use('/ai', aiRoutes); 
router.use('/partner-requests', partnerRequestRoutes);
router.use('/notifications', notificationRoutes);
router.use('/admin', adminRoutes);
router.use('/ngo', ngoRoutes);
router.use('/chat', chatRoutes);

module.exports = router;

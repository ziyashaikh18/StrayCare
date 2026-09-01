const express = require('express');
const healthRoutes = require('./healthRoutes');
const testRoutes = require('./testRoutes');
const authRoutes = require('./authRoutes');

const router = express.Router();

// Mount sub-routes
router.use('/health', healthRoutes);
router.use('/test', testRoutes);
router.use('/auth', authRoutes);

module.exports = router;

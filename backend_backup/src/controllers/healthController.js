const mongoose = require('mongoose');

/**
 * Controller for Health Check Endpoint
 * GET /api/health
 */
const getHealthStatus = (req, res) => {
  const mongoStates = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };

  const dbState = mongoose.connection.readyState;

  res.status(200).json({
    success: true,
    message: 'Server is healthy and running',
    database: {
      status: mongoStates[dbState] || 'unknown',
      connected: dbState === 1,
    },
    timestamp: new Date().toISOString(),
    uptime: `${Math.floor(process.uptime())}s`,
  });
};

module.exports = {
  getHealthStatus,
};

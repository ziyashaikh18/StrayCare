const express = require('express');
const cors = require('cors');
const config = require('./config/env');
const connectDB = require('./config/db');
const routes = require('./routes');
const errorHandler = require('./middleware/errorHandler');
const notFoundHandler = require('./middleware/notFoundHandler');
const path = require('path');   // add near the top with other requires

// Serve uploaded report images statically, e.g.
// http://localhost:5000/uploads/reports/report_123.jpg


// Initialize express app
const app = express();

// Connect to MongoDB Database
connectDB();

// Global Middlewares
app.use(cors()); // Enable Cross-Origin Resource Sharing
app.use(express.json()); // Parse incoming JSON request bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// Root Route
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Welcome to StrayCare Backend API',
    endpoints: {
      health: '/api/health',
      test: '/api/test',
      auth: '/api/auth (register, login, verify-email, resend-verification, forgot-password, reset-password, me)',
    },
  });
});

// Base API Routes
app.use('/api', routes);

// 404 Route Handler for undefined routes
app.use(notFoundHandler);

// Centralized Error Handling Middleware
app.use(errorHandler);

// Start server on configured PORT
const PORT = config.port;
const server = app.listen(PORT, () => {
  console.log(`=========================================`);
  console.log(`🚀 Server running in ${config.nodeEnv} mode`);
  console.log(`📡 Listening on: http://localhost:${PORT}`);
  console.log(`🩺 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`🧪 Test Route:   http://localhost:${PORT}/api/test`);
  console.log(`=========================================`);
});

module.exports = { app, server };

const dotenv = require('dotenv');

// Load environment variables from .env file
dotenv.config();

const config = {
  port: process.env.PORT || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  mongoUri: process.env.MONGO_URI,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
};

if (!config.jwtSecret) {
  console.warn(
    '⚠️  JWT_SECRET is not set in .env — auth routes will fail until you set one.'
  );
}

module.exports = config;

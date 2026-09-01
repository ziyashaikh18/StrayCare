const mongoose = require('mongoose');
const dns = require('dns');
const config = require('./env');

// Set reliable public DNS servers for MongoDB SRV resolution
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (e) {
  // fallback silently
}

/**
 * Connect to MongoDB Atlas Database
 */
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(config.mongoUri);
    console.log(`🍃 MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;

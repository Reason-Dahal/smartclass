const dns = require('dns');
const mongoose = require('mongoose');

// Override DNS to bypass ISP restrictions on MongoDB SRV lookups
dns.setServers(['8.8.8.8']);

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`MongoDB connection error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
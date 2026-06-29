const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 30000,
      connectTimeoutMS: 30000,
      // ── Connection pool — up to 50 simultaneous DB connections ──────────────
      maxPoolSize: 50,    // max open connections to MongoDB at once
      minPoolSize: 5,     // keep 5 warm connections ready at all times
      socketTimeoutMS: 45000,  // close idle sockets after 45s to free pool slots
    });
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (err) {
    console.error('❌ MongoDB connection error:', err.message);
    // Don't exit process in development to allow server to start for health checks
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    }
  }
};

mongoose.connection.on('disconnected', () => {
  console.warn('⚠️ MongoDB disconnected. Reconnecting...');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ MongoDB error:', err);
});

module.exports = connectDB;

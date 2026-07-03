const Redis = require('ioredis');

// Parse REDIS_URL if it exists, otherwise use host/port
let redisConfig = {
  host: process.env.REDIS_HOST || '127.0.0.1',
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD || undefined,
  maxRetriesPerRequest: null, // Required for BullMQ
};

if (!process.env.REDIS_URL) {
  console.error('❌ ERROR: REDIS_URL environment variable is missing. Falling back to 127.0.0.1');
} else {
  console.log('✅ REDIS_URL is present. Attempting to parse...');
}

if (process.env.REDIS_URL) {
  try {
    let urlStr = process.env.REDIS_URL;
    if (!urlStr.startsWith('redis://') && !urlStr.startsWith('rediss://')) {
      // If it's a Render external URL without protocol, assume rediss:// (TLS) if it contains "render.com", else redis://
      urlStr = urlStr.includes('render.com') ? 'rediss://' + urlStr : 'redis://' + urlStr;
    }
    const url = new URL(urlStr);
    redisConfig = {
      host: url.hostname || '127.0.0.1',
      port: parseInt(url.port) || 6379,
      password: url.password ? decodeURIComponent(url.password) : undefined,
      username: url.username ? decodeURIComponent(url.username) : undefined,
      tls: url.protocol === 'rediss:' ? { rejectUnauthorized: false } : undefined, // Added rejectUnauthorized: false for external Redis
      maxRetriesPerRequest: null,
    };
    console.log(`✅ Parsed Redis Config -> Host: ${redisConfig.host}, Port: ${redisConfig.port}, TLS: ${!!redisConfig.tls}`);
  } catch (e) {
    console.error('❌ Failed to parse REDIS_URL:', e);
  }
}

// Global client for caching/rate-limiting
const redisClient = new Redis({
  ...redisConfig,
  commandTimeout: 3000,
  // Stop retrying after ~60 seconds — prevents infinite log spam when Redis is down
  retryStrategy: (times) => {
    if (times > 8) {
      console.error('❌ Redis: Could not connect after multiple attempts. Rate limiting and session features will be degraded.');
      return null; // stop retrying
    }
    return Math.min(times * 1000, 8000); // exponential back-off, max 8s between retries
  },
  // enableOfflineQueue is intentionally left ON (default: true)
  // rate-limit-redis and socket.io-adapter send commands during startup before
  // the connection is ready — disabling the queue causes them to crash.
});

redisClient.on('connect', () => {
  console.log('✅ Connected to Redis successfully');
});

redisClient.on('error', (err) => {
  // Suppress repeated ECONNREFUSED noise — only log the first one
  if (!redisClient._loggedConnErr) {
    console.error('❌ Redis connection error (will retry):', err.message);
    if (err.message.includes('ECONNREFUSED') && err.message.includes('127.0.0.1')) {
      console.error('   👉 Fix: Set REDIS_URL in your .env file, or run: brew services start redis');
    }
    redisClient._loggedConnErr = true;
  }
});

module.exports = {
  redisClient,
  redisConfig
};

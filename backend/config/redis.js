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
const redisClient = new Redis(redisConfig);

redisClient.on('connect', () => {
  console.log('✅ Connected to Redis successfully');
});

redisClient.on('error', (err) => {
  console.error('❌ Redis connection error (will retry automatically):', err.message);
});

module.exports = {
  redisClient,
  redisConfig
};

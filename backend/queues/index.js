const { Queue } = require('bullmq');
const { redisConfig } = require('../config/redis');

// Initialize Queues
const kycQueue = new Queue('kyc', { connection: redisConfig });
const matchQueue = new Queue('match', { connection: redisConfig });
const notificationQueue = new Queue('notification', { connection: redisConfig });

module.exports = {
  kycQueue,
  matchQueue,
  notificationQueue
};

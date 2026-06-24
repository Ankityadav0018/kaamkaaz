// Initialize and start all workers
const kycWorker = require('./kycWorker');
const matchWorker = require('./matchWorker');
const notificationWorker = require('./notificationWorker');

console.log('✅ BullMQ Workers Initialized');

module.exports = {
  kycWorker,
  matchWorker,
  notificationWorker
};

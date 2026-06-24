const { Worker } = require('bullmq');
const { redisConfig } = require('../config/redis');
const { createNotification } = require('../utils/notification');

// Handles bulk dispatching of FCM pushes or SMS
const notificationWorker = new Worker('notification', async job => {
  const { userId, title, message, type, data } = job.data;
  
  if (job.name === 'send_push') {
    console.log(`[Notification Worker] Sending push to ${userId}: ${title}`);
    
    // Use the existing notification utility
    // We pass io as null since this might just be the push portion, or we can instantiate io if needed
    await createNotification({
      userId,
      title,
      message,
      type,
      data,
      io: null // Assuming we handle socket emission elsewhere or we adapt createNotification
    });
    
    console.log(`[Notification Worker] Successfully sent push to ${userId}`);
  }
}, { 
  connection: redisConfig,
  concurrency: 10, // Can be higher since it's mostly network I/O
});

notificationWorker.on('failed', (job, err) => {
  console.error(`[Notification Worker] Job ${job.id} failed with error: ${err.message}`);
});

module.exports = notificationWorker;

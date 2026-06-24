const { Queue, Worker } = require('bullmq');
const { redisConfig } = require('../config/redis');

// Create a Notification Queue
const notificationQueue = new Queue('NotificationQueue', { connection: redisConfig });

// Create a Worker to process notifications in the background
const notificationWorker = new Worker('NotificationQueue', async job => {
  console.log(`[BullMQ] Processing job ${job.id} of type ${job.name}`);
  const { fcmToken, title, body, data } = job.data;
  
  // Here we would normally call Firebase Admin SDK
  // await admin.messaging().send({ ... })
  
  // Simulate network delay
  await new Promise(resolve => setTimeout(resolve, 500));
  
  console.log(`[BullMQ] Successfully processed push notification for ${job.id}`);
}, { connection: redisConfig });

notificationWorker.on('completed', job => {
  console.log(`[BullMQ] Job with id ${job.id} has been completed`);
});

notificationWorker.on('failed', (job, err) => {
  console.error(`[BullMQ] Job with id ${job.id} has failed with ${err.message}`);
});

module.exports = {
  notificationQueue
};

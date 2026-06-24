const { Worker } = require('bullmq');
const { redisConfig } = require('../config/redis');

// In a real app, this would integrate with OCR/admin review. 
// For now, it just simulates an async process.
const kycWorker = new Worker('kyc', async job => {
  const { userId, type } = job.data;
  
  if (type === 'process_submission') {
    console.log(`[KYC Worker] Started processing submission for user: ${userId}`);
    // Simulate async work (e.g. OCR API, background checks)
    await new Promise(resolve => setTimeout(resolve, 2000));
    console.log(`[KYC Worker] Completed processing submission for user: ${userId}`);
    
    // You could potentially auto-approve here based on some logic, or notify admins.
  }
}, { 
  connection: redisConfig,
  concurrency: 5, // process up to 5 KYC jobs at once
  limiter: { max: 10, duration: 1000 } // Rate limiting for external API safety
});

kycWorker.on('failed', (job, err) => {
  console.error(`[KYC Worker] Job ${job.id} failed with error: ${err.message}`);
});

kycWorker.on('completed', (job) => {
  console.log(`[KYC Worker] Job ${job.id} has completed!`);
});

module.exports = kycWorker;

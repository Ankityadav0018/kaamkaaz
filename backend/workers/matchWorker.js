const { Worker } = require('bullmq');
const { redisConfig } = require('../config/redis');

// Background job to recalculate matching workers when a new job is posted
const matchWorker = new Worker('match', async job => {
  const { jobId, location, skills } = job.data;
  
  if (job.name === 'recalculate_matches') {
    console.log(`[Match Worker] Recalculating matches for Job: ${jobId}`);
    // Simulate complex geospatial + skills matching query
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    console.log(`[Match Worker] Matches calculated and cached for Job: ${jobId}`);
  }
}, { 
  connection: redisConfig,
  concurrency: 2 // High CPU bound, keep concurrency lower
});

matchWorker.on('failed', (job, err) => {
  console.error(`[Match Worker] Job ${job.id} failed with error: ${err.message}`);
});

module.exports = matchWorker;

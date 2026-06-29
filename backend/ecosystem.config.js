/**
 * ecosystem.config.js — PM2 Cluster Configuration
 *
 * Starts one worker process per CPU core (e.g. 4 cores = 4 workers).
 * Each worker handles its own event loop, multiplying total throughput linearly.
 *
 * The Socket.io Redis adapter in server.js ensures all workers share the same
 * socket rooms — messages sent from worker #1 reach clients on worker #2.
 *
 * ── Commands ──────────────────────────────────────────────────────────────────
 *   Start:   pm2 start ecosystem.config.js
 *   Reload:  pm2 reload ecosystem.config.js   ← zero-downtime restart
 *   Stop:    pm2 stop kaamkaaz-backend
 *   Logs:    pm2 logs kaamkaaz-backend
 *   Monitor: pm2 monit
 *   Status:  pm2 list
 *
 * ── On Render.com ──────────────────────────────────────────────────────────────
 * Set start command to:  pm2-runtime start ecosystem.config.js
 * (pm2-runtime keeps the process in foreground, required for Render)
 */

module.exports = {
  apps: [
    {
      name:          'kaamkaaz-backend',
      script:        'server.js',

      // ── Cluster mode: one worker per CPU core ───────────────────────────────
      exec_mode:     'cluster',
      instances:     'max',   // auto-detect CPU core count; set a number (e.g. 2) on small VPS

      // ── Reliability ──────────────────────────────────────────────────────────
      autorestart:   true,
      watch:         false,   // never watch in production (causes restart loops)
      max_restarts:  10,
      restart_delay: 3000,    // wait 3s between crash restarts

      // ── Memory guard — restart worker if it exceeds 450MB ───────────────────
      max_memory_restart: '450M',

      // ── Graceful shutdown — let in-flight requests finish before killing ─────
      kill_timeout:  5000,
      wait_ready:    true,
      listen_timeout: 10000,

      // ── Zero-downtime reload — new workers start before old ones die ─────────
      // pm2 reload ecosystem.config.js
      // This means users never see downtime during deploys.

      // ── Environment ──────────────────────────────────────────────────────────
      env: {
        NODE_ENV: 'development',
        PORT:     5005,
      },
      env_production: {
        NODE_ENV: 'production',
        PORT:     5005,
      },

      // ── Logging ──────────────────────────────────────────────────────────────
      error_file:   './logs/pm2-error.log',
      out_file:     './logs/pm2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      merge_logs:   true,  // single log file across all workers
    }
  ]
};

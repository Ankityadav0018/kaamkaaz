const express = require('express');
const http = require('http');
const socketio = require('socket.io');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const helmet = require('helmet');
const cookieParser = require('cookie-parser');
const connectDB = require('./config/db');
const i18next = require('./config/i18n');
const i18nMiddleware = require('i18next-http-middleware');
const errorHandler = require('./middleware/errorHandler');
const { setupLogSanitizer, sanitizeRequestBody } = require('./middleware/logSanitizer');

// ── Activate log sanitization FIRST (before any other code logs) ────────────
setupLogSanitizer();

dotenv.config();

// Validate Environment Variables
const requiredEnv = ['JWT_SECRET', 'MONGODB_URI', 'CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET', 'SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
const missingEnv = requiredEnv.filter(key => !process.env[key]);
if (missingEnv.length > 0) {
  console.error('❌ CRITICAL ERROR: Missing environment variables:', missingEnv.join(', '));
  console.error('⚠️ The server cannot start without these variables. Please add them to your Render dashboard or .env file.');
  process.exit(1);
}

console.log('🔑 JWT_SECRET: ✅');
console.log('🗄️  MONGODB_URI: ✅');
console.log('☁️  CLOUDINARY: ✅');

const app = express();

app.get('/', (req, res) => {
  res.status(200).json({
    status: 'running',
    message: '🚀 Kaamkaaz Backend is live!',
    version: '1.0.0'
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    uptime: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development'
  });
});

// ── Security Headers (Section 5.2) ──────────────────────────────────────────
app.use(helmet({
  // Prevent clickjacking
  frameguard: { action: 'deny' },
  // Prevent MIME-type sniffing
  noSniff: true,
  // Force HTTPS for 1 year including subdomains
  hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
  // Don't send referrer in cross-origin requests
  referrerPolicy: { policy: 'no-referrer' },
  // Content Security Policy — restrict to own domain only
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc:  ["'self'"],
      styleSrc:   ["'self'", "'unsafe-inline'"],
      imgSrc:     ["'self'", 'data:', 'https://res.cloudinary.com'],
      connectSrc: ["'self'"],
      fontSrc:    ["'self'"],
      objectSrc:  ["'none'"],
      frameAncestors: ["'none'"],
      upgradeInsecureRequests: []
    }
  },
  // Disable camera, mic, geolocation
  permissionsPolicy: {
    features: {
      camera:      ["'none'"],
      microphone:  ["'none'"],
      geolocation: ["'none'"]
    }
  },
  crossOriginResourcePolicy: { policy: 'cross-origin' }
}));

const server = http.createServer(app);
const io = socketio(server, {
  cors: { origin: process.env.FRONTEND_URL || '*', methods: ['GET', 'POST'] },
  // Tune for high concurrency: larger ping timeout tolerates slow clients
  pingTimeout:  60000,
  pingInterval: 25000,
});

// ── Socket.io Redis Adapter — required for PM2 cluster mode ──────────────────
// Without this, socket events emitted on worker #1 won't reach clients
// connected to worker #2. The adapter syncs all rooms across processes.
try {
  const { createAdapter } = require('@socket.io/redis-adapter');
  const { redisClient }   = require('./config/redis');
  const pubClient = redisClient;
  const subClient = redisClient.duplicate({
    retryStrategy: (times) => times > 8 ? null : Math.min(times * 1000, 8000),
    // enableOfflineQueue left ON — adapter calls subscribe() during init before
    // the connection is fully ready; the queue buffers it safely.
  });
  // Must attach error handler — Node throws on unhandled 'error' events
  subClient.on('error', (err) => {
    if (!subClient._loggedErr) {
      console.error('❌ Socket.io Redis sub-client error:', err.message);
      subClient._loggedErr = true;
    }
  });
  io.adapter(createAdapter(pubClient, subClient));
  console.log('✅ Socket.io Redis adapter active (cluster-ready)');
} catch (e) {
  console.warn('⚠️  Socket.io Redis adapter not loaded:', e.message);
}




// Socket.io — user rooms for real-time notifications and chat
io.on('connection', (socket) => {
  console.log('🔌 Socket connected:', socket.id);

  socket.on('join', (userId) => {
    if (!userId) {
      console.log('⚠️ Join event received with null/undefined userId');
      return;
    }
    socket.join(userId.toString());
    console.log(`👤 User joined room: ${userId} (Socket ID: ${socket.id})`);
  });

  socket.on('send_message', async (data) => {
    try {
      const Message = require('./models/Message');
      const { jobId, senderId, receiverId, text, audioUrl } = data;

      console.log(`📩 Message from ${senderId} to ${receiverId} for job ${jobId}: "${text}" (Audio: ${audioUrl})`);

      // Save to database
      const newMessage = await Message.create({
        jobId,
        senderId,
        receiverId,
        text,
        audioUrl
      });

      // Convert to plain object for socket emission
      const messageData = newMessage.toObject();

      // Emit to receiver's room
      const receiverRoom = receiverId.toString();
      io.to(receiverRoom).emit('receive_message', messageData);
      console.log(`📡 Emitted to room ${receiverRoom}: receive_message`);

      // Emit back to sender to confirm
      socket.emit('message_sent', messageData);

      // Optionally create a notification for the receiver
      try {
        const { createNotification } = require('./utils/notification');
        await createNotification({
          userId: receiverId,
          title: 'New Message',
          message: text,
          type: 'chat',
          relatedId: jobId,
          io // Pass io to emit socket notification
        });
      } catch (notifyErr) {
        console.error('❌ Notification error:', notifyErr.message);
      }

    } catch (err) {
      console.error('❌ Error sending message via socket:', err.message);
    }
  });

  socket.on('disconnect', () => {
    console.log('🔌 Socket disconnected:', socket.id);
  });
});

app.set('io', io);

// ── CORS (Section 5.4) — whitelist only known origins ───────────────────────
const rawOrigins = process.env.ALLOWED_ORIGINS || '';
const allowedOrigins = rawOrigins
  .split(',')
  .map(o => o.trim())
  .filter(Boolean);

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl, server-to-server)
    if (!origin) return callback(null, true);
    // In development allow all; in production enforce whitelist
    if (process.env.NODE_ENV !== 'production') return callback(null, true);
    if (allowedOrigins.includes(origin)) return callback(null, true);
    callback(new Error(`CORS: origin '${origin}' not allowed`));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  credentials: true,
  allowedHeaders: ['Content-Type', 'Authorization', 'x-admin-intent', 'x-admin-co-approval']
}));

// Webhook routes must be placed before express.json() to parse raw body
app.use('/api/webhooks', require('./routes/webhookRoutes'));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
app.use(cookieParser()); // Required for httpOnly refresh token cookie (Section 1.2)
app.use(morgan('dev'));
app.use(sanitizeRequestBody); // Sanitize req.body for downstream logging (Section 6)


// i18n Localization Middleware
app.use(i18nMiddleware.handle(i18next));

// API Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/upload', require('./routes/uploadRoutes'));
app.use('/api/jobs', require('./routes/jobs'));
app.use('/api/applications', require('./routes/applications'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/ratings', require('./routes/ratings'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/chat', require('./routes/chat'));
app.use('/api/driver', require('./routes/driver'));
app.use('/api/disputes', require('./routes/dispute'));
app.use('/api/worker', require('./routes/worker'));
app.use('/api/recruiter', require('./routes/recruiter'));
app.use('/api/referral', require('./routes/referral'));
app.use('/api/skill-badges', require('./routes/skillBadge'));
app.use('/api/reports', require('./routes/reportRoutes'));
app.use('/api/sos', require('./routes/sos'));
app.use('/api/config', require('./routes/configRoutes'));
app.use('/api/ai', require('./routes/aiRoutes'));
app.use('/api/wallet', require('./routes/walletRoutes'));
// Admin IP confirmation (Layer 3 — no auth required, link from email)
app.use('/api/admin', require('./routes/adminConfirm'));


// Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    uptime: Math.floor(process.uptime()),
    timestamp: new Date().toISOString()
  });
});

app.get('/delete-account', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>Account Deletion Request - Kaamkaaz</title>
        <style>
          body { font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f4f4f9; color: #333; }
          .card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); max-width: 500px; text-align: center; }
          h1 { color: #d32f2f; margin-bottom: 20px; }
          p { line-height: 1.6; color: #555; }
          .contact { background: #fdf2f2; padding: 15px; border-radius: 8px; border-left: 4px solid #d32f2f; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>Kaamkaaz Account Deletion</h1>
          <p>We are sorry to see you go. If you wish to delete your account and all associated data, please follow the steps below.</p>
          <div class="contact">
            <p>To request Kaamkaaz account deletion, email <strong>support@kaamkaaz.app</strong> with your registered mobile number.</p>
          </div>
          <p style="font-size: 0.9em; color: #888; margin-top: 20px;">Once processed, your data cannot be recovered. This includes your job history, ratings, and profile verification status.</p>
        </div>
      </body>
    </html>
  `);
});

// Security monitoring — track 401/403 per IP, auto-block on abuse (Section 7)
app.use(require('./middleware/securityMonitor'));

// Global error handler
app.use(errorHandler);


const PORT = process.env.PORT || 5005;

// Start Server after DB Connection
const startServer = async () => {
  try {
    await connectDB();
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`\n🚀 Kaamkaaz Server running on port ${PORT}`);
      console.log(`📋 Mode: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🌐 Health: http://localhost:${PORT}/health\n`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err.message);
    process.exit(1);
  }
};

startServer();

module.exports = app;

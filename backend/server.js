const express = require('express');
const http = require('http');
const socketio = require('socket.io');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const helmet = require('helmet');
const connectDB = require('./config/db');
// Firebase removed
const i18next = require('./config/i18n');
const i18nMiddleware = require('i18next-http-middleware');
const errorHandler = require('./middleware/errorHandler');

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

// Security Hardening
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

const server = http.createServer(app);
const io = socketio(server, {
  cors: { origin: process.env.FRONTEND_URL || '*', methods: ['GET', 'POST'] }
});

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

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  credentials: true
}));

// Webhook routes must be placed before express.json() to parse raw body
app.use('/api/webhooks', require('./routes/webhookRoutes'));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
app.use(morgan('dev'));

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

const jwt = require('jsonwebtoken');
const Message = require('./models/Message');
const User = require('./models/User');

module.exports = function(io) {
  // JWT Middleware for Socket.io
  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Authentication error: Token missing'));
    }

    try {
      // First try Supabase JWT Secret
      const decoded = jwt.verify(token, process.env.SUPABASE_JWT_SECRET);
      socket.user = decoded; // Contains id (from custom claims or raw auth.uid)
      
      // We assume standard JWT payloads. Sub = id if missing
      if (!socket.user.id && socket.user.sub) {
        socket.user.id = socket.user.sub;
      }
      
      next();
    } catch (err) {
      // Fallback to old JWT_SECRET if using dual tokens
      try {
        const decodedFallback = jwt.verify(token, process.env.JWT_SECRET);
        socket.user = decodedFallback;
        next();
      } catch (fallbackErr) {
        return next(new Error('Authentication error: Invalid token'));
      }
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user.id || socket.user._id;
    console.log(`🔌 Socket connected: ${socket.id} (User: ${userId})`);

    // 1. Join personal room for cross-application notifications / delivery receipts
    socket.join(`user_${userId}`);
    
    // Broadcast online status to everyone
    socket.broadcast.emit('user_online', { userId });

    // Handle legacy join event (for notifications)
    socket.on('join', (reqUserId) => {
      if (reqUserId) {
        socket.join(reqUserId.toString());
      }
    });

    // 2. Room logic for Application-scoped Chat
    socket.on('join_room', (data) => {
      if (data.room) {
        socket.join(data.room);
        console.log(`👤 User ${userId} joined room: ${data.room}`);
      }
    });

    socket.on('leave_room', (data) => {
      if (data.room) {
        socket.leave(data.room);
        console.log(`👤 User ${userId} left room: ${data.room}`);
      }
    });

    // 3. Send Message
    socket.on('send_message', async (data) => {
      try {
        const { applicationId, receiverId, text, audioUrl } = data;

        const newMessage = await Message.create({
          applicationId,
          senderId: userId,
          receiverId,
          text,
          audioUrl,
          status: 'sent'
        });

        const messageData = newMessage.toObject();

        // Emit to the specific application room
        const roomName = `chat_app_${applicationId}`;
        io.to(roomName).emit('receive_message', messageData);

        // Also emit to receiver's personal room to trigger unread badge increment if they are outside the chat room
        io.to(`user_${receiverId}`).emit('receive_message', messageData);

        // Emit back to sender to confirm
        socket.emit('message_sent', messageData);

        // Send Push Notification
        try {
          const { createNotification } = require('./utils/notification');
          await createNotification({
            userId: receiverId,
            title: 'New Message',
            message: text || 'Sent an attachment',
            type: 'chat',
            relatedId: applicationId,
            io // Pass io to emit socket notification
          });
        } catch (notifyErr) {
          console.error('❌ Notification error:', notifyErr.message);
        }

      } catch (err) {
        console.error('❌ Error sending message via socket:', err.message);
      }
    });

    // 4. Message Delivered
    socket.on('message_delivered', async (data) => {
      try {
        const { messageId, senderId } = data;
        await Message.findByIdAndUpdate(messageId, { status: 'delivered' });
        
        // Notify the original sender that their message was delivered
        io.to(`user_${senderId}`).emit('message_delivered_ack', { messageId });
      } catch (err) {
        console.error('❌ Error updating message delivery:', err.message);
      }
    });

    // 5. Message Read
    socket.on('message_read', async (data) => {
      try {
        const { messageId, senderId } = data;
        await Message.findByIdAndUpdate(messageId, { status: 'read' });
        
        // Notify the original sender
        io.to(`user_${senderId}`).emit('message_read_ack', { messageId });
      } catch (err) {
        console.error('❌ Error updating message read:', err.message);
      }
    });

    socket.on('disconnect', () => {
      console.log(`🔌 Socket disconnected: ${socket.id}`);
      socket.broadcast.emit('user_offline', { userId });
    });
  });
};

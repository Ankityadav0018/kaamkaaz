const Notification = require('../models/Notification');
const User = require('../models/User');
const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
try {
  const serviceAccount = require('../config/firebase-service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase Admin initialized successfully');
} catch (error) {
  console.error('Failed to initialize Firebase Admin:', error.message);
}

/**
 * Creates a notification, emits via socket, and sends via FCM Push Notification.
 */
const createNotification = async ({ userId, title, message, type, relatedId, io }) => {
  try {
    const notif = await Notification.create({ userId, title, message, type, relatedId });

    // 1. Send via Socket.io (In-app real-time)
    if (io) {
      io.to(userId.toString()).emit('notification', {
        _id: notif._id,
        title,
        message,
        type,
        isRead: false,
        createdAt: notif.createdAt
      });
    }

    // 2. Send via Firebase Cloud Messaging (Background Push)
    const user = await User.findById(userId).select('fcmToken');
    if (user && user.fcmToken) {
      const payload = {
        notification: {
          title: title,
          body: message,
        },
        data: {
          type: type || 'general',
          relatedId: relatedId ? relatedId.toString() : '',
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        token: user.fcmToken
      };

      try {
        await admin.messaging().send(payload);
      } catch (fcmError) {
        console.error(`FCM send failed for user ${userId}:`, fcmError.message);
        // If token is unregistered, we could clear it here
        if (fcmError.code === 'messaging/registration-token-not-registered') {
          await User.findByIdAndUpdate(userId, { $unset: { fcmToken: 1 } });
        }
      }
    }

    return notif;
  } catch (err) {
    console.error('❌ Notification creation failed:', err.message);
  }
};

/**
 * Creates an urgent alarm notification for workers.
 */
const createUrgentNotification = async ({ userId, title, message, relatedId, io }) => {
  try {
    const user = await User.findById(userId).select('fcmToken urgentAlertsEnabled urgentAlertCountToday urgentAlertLastSentAt');
    if (!user || !user.fcmToken || !user.urgentAlertsEnabled) return;

    const today = new Date().setHours(0, 0, 0, 0);
    const lastSentAt = user.urgentAlertLastSentAt ? new Date(user.urgentAlertLastSentAt).setHours(0, 0, 0, 0) : null;
    
    let countToday = user.urgentAlertCountToday || 0;
    if (lastSentAt !== today) {
      countToday = 0;
    }

    if (countToday >= 3) return; // Limit reached

    // Create DB notification
    const notif = await Notification.create({ userId, title, message, type: 'urgent_job', relatedId });

    if (io) {
      io.to(userId.toString()).emit('notification', {
        _id: notif._id,
        title,
        message,
        type: 'urgent_job',
        isRead: false,
        createdAt: notif.createdAt
      });
    }

    const payload = {
      data: {
        type: 'urgent_job',
        title: title,
        message: message,
        relatedId: relatedId ? relatedId.toString() : '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: 'high'
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: message
            },
            sound: {
              critical: 1,
              name: 'default',
              volume: 1.0
            }
          }
        }
      },
      token: user.fcmToken
    };

    try {
      await admin.messaging().send(payload);
      
      // Update limits
      await User.findByIdAndUpdate(userId, {
        urgentAlertCountToday: countToday + 1,
        urgentAlertLastSentAt: new Date()
      });
    } catch (fcmError) {
      console.error(`FCM urgent send failed for user ${userId}:`, fcmError.message);
      if (fcmError.code === 'messaging/registration-token-not-registered') {
        await User.findByIdAndUpdate(userId, { $unset: { fcmToken: 1 } });
      }
    }

    return notif;
  } catch (err) {
    console.error('❌ Urgent notification creation failed:', err.message);
  }
};


const notifyAdmins = async ({ title, message, type, relatedId, io }) => {
  try {
    const admins = await User.find({ role: 'admin' }).select('_id');
    for (const adminUser of admins) {
      await createNotification({
        userId: adminUser._id,
        title,
        message,
        type,
        relatedId,
        io
      });
    }
  } catch (err) {
    console.error('❌ notifyAdmins failed:', err.message);
  }
};

module.exports = { createNotification, createUrgentNotification, notifyAdmins };

const mongoose = require('mongoose');
const Message = require('../models/Message');
const Job = require('../models/Job');
const User = require('../models/User');

// @desc    Get chat history for a specific job between two users
// @route   GET /api/chat/:jobId/:otherUserId
// @access  Private
exports.getChatHistory = async (req, res) => {
  try {
    const { jobId, otherUserId } = req.params;
    const currentUserId = req.user.id;

    const messages = await Message.find({
      jobId,
      $or: [
        { senderId: currentUserId, receiverId: otherUserId },
        { senderId: otherUserId, receiverId: currentUserId }
      ]
    }).sort({ createdAt: 1 });

    // Mark received messages as read
    await Message.updateMany(
      { jobId, senderId: otherUserId, receiverId: currentUserId, isRead: false },
      { $set: { isRead: true } }
    );

    res.status(200).json({ success: true, data: messages });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get user's inbox (list of ongoing chats)
// @route   GET /api/chat/inbox
// @access  Private
exports.getInbox = async (req, res) => {
  try {
    const currentUserId = req.user.id;

    // Aggregate latest message for each combination of jobId and the other user
    const latestMessages = await Message.aggregate([
      {
        $match: {
          $or: [
            { senderId: new mongoose.Types.ObjectId(currentUserId) },
            { receiverId: new mongoose.Types.ObjectId(currentUserId) }
          ]
        }
      },
      {
        $sort: { createdAt: -1 }
      },
      {
        $group: {
          _id: {
            jobId: '$jobId',
            otherUserId: {
              $cond: [
                { $eq: ['$senderId', new mongoose.Types.ObjectId(currentUserId)] },
                '$receiverId',
                '$senderId'
              ]
            }
          },
          latestMessage: { $first: '$$ROOT' },
          unreadCount: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$receiverId', new mongoose.Types.ObjectId(currentUserId)] },
                    { $eq: ['$isRead', false] }
                  ]
                },
                1,
                0
              ]
            }
          }
        }
      }
    ]);

    // Populate Job and Other User info
    const inbox = await Promise.all(latestMessages.map(async (item) => {
      const job = await Job.findById(item._id.jobId).select('title');
      const user = await User.findById(item._id.otherUserId).select('name profileImage role');
      return {
        job,
        user,
        latestMessage: item.latestMessage,
        unreadCount: item.unreadCount
      };
    }));

    // Sort by latest message descending
    inbox.sort((a, b) => new Date(b.latestMessage.createdAt) - new Date(a.latestMessage.createdAt));

    res.status(200).json({ success: true, data: inbox });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

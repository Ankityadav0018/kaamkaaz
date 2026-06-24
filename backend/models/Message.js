const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  jobId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Job',
    required: true
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  receiverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  text: {
    type: String,
    required: false,
    trim: true
  },
  audioUrl: {
    type: String,
    required: false
  },
  isRead: {
    type: Boolean,
    default: false
  }
}, { timestamps: true });

messageSchema.index({ jobId: 1, createdAt: 1 });
messageSchema.index({ senderId: 1, receiverId: 1 });

module.exports = mongoose.model('Message', messageSchema);

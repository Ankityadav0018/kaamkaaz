require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const uri = process.env.MONGODB_URI;

mongoose.connect(uri).then(async () => {
  const users = await User.find({ phone: { $in: ['9000000001', '9000000002'] } });
  
  for (const user of users) {
    user.password = 'Kaamkaaz@123';
    await user.save();
    console.log(`Reset password for ${user.phone} (${user.role}) to Kaamkaaz@123`);
  }
  process.exit(0);
});

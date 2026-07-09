require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const uri = process.env.MONGODB_URI;

mongoose.connect(uri).then(async () => {
  const users = await User.find({ phone: { $in: ['9999999999', '9000000001', '9000000002'] } }).select('+password');
  console.log(`Found ${users.length} test users`);
  
  const testPasswords = ['123456', '12345678', 'password123', 'password', 'Ankit@2004', 'Test@123', 'admin123', 'Admin@123'];
  
  for (const user of users) {
    console.log(`\nUser: ${user.phone} (${user.role}) - Email: ${user.email}`);
    let matched = false;
    for (const pwd of testPasswords) {
      if (await user.matchPassword(pwd)) {
        console.log(`=> Password is: ${pwd}`);
        matched = true;
        break;
      }
    }
    if (!matched) console.log('=> Password not found in common list.');
  }
  process.exit(0);
});

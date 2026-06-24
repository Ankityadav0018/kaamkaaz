const mongoose = require('mongoose');
const User = require('./models/User');
require('dotenv').config();

const updateToAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    const phone = '9636147272';
    const user = await User.findOne({ phone });

    if (!user) {
      console.log('User not found. Creating new admin...');
      const admin = new User({
        name: 'Ankit',
        phone,
        password: '[PASSWORD]',
        role: 'admin',
        isPhoneVerified: true,
        kycStatus: 'approved'
      });
      await admin.save();
      console.log('Admin created.');
    } else {
      user.role = 'admin';
      user.kycStatus = 'approved';
      await user.save();
      console.log('User updated to Admin role.');
    }
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};
updateToAdmin();

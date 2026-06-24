const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');

async function testSearch() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const name = 'Admin';
    const query = {
      name: { $regex: name, $options: 'i' },
      isBlocked: false,
    };

    const users = await User.find(query)
      .select('name role profileImage village skills rating experienceDays completedJobsCount');
    
    console.log(`Search for "${name}" found ${users.length} users:`);
    console.log(JSON.stringify(users, null, 2));

    process.exit(0);
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  }
}

testSearch();

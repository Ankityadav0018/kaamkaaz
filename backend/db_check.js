const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

async function checkDb() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('Collections found:', collections.map(c => c.name).join(', '));
    
    const userCount = await mongoose.connection.db.collection('users').countDocuments();
    const jobCount = await mongoose.connection.db.collection('jobs').countDocuments();
    const appCount = await mongoose.connection.db.collection('applications').countDocuments();
    
    console.log(`Stats: ${userCount} Users, ${jobCount} Jobs, ${appCount} Applications`);
    
    process.exit(0);
  } catch (err) {
    console.error('❌ DB Error:', err.message);
    process.exit(1);
  }
}

checkDb();

require('dotenv').config({ path: __dirname + '/../.env' });
const mongoose = require('mongoose');
const Application = require('../models/Application');

async function migrateStatus() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB.');

    const map = {
      applied: 'pending',
      accepted: 'hired',
      withdrawn: 'rejected',
      completed: 'hired',
    };

    for (const [old, next] of Object.entries(map)) {
      const result = await Application.updateMany(
        { status: old },
        { $set: { status: next } }
      );
      console.log(`Migrated '${old}' → '${next}'. Modified count: ${result.modifiedCount}`);
    }

    console.log('Migration completed successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrateStatus();

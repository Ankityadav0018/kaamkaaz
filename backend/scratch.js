require('dotenv').config();
const mongoose = require('mongoose');

const uri = process.env.MONGO_URI;

mongoose.connect(uri)
  .then(async () => {
    const db = mongoose.connection.db;
    const result = await db.collection('users').deleteMany({ phone: "9999999999" });
    console.log("Deleted:", result.deletedCount);
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });

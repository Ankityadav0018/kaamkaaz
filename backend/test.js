const mongoose = require('mongoose');
const Job = require('./models/Job');
const Application = require('./models/Application');
const User = require('./models/User');

mongoose.connect('mongodb://localhost:27017/kaamkaaz').then(async () => {
  const users = await User.find({ role: 'recruiter' }).limit(5);
  for (let u of users) {
    const jobIds = await Job.find({ recruiterId: u._id }).distinct('_id');
    const pastWorkers = await Application.aggregate([
      { $match: { jobId: { $in: jobIds }, status: { $in: ['accepted', 'completed'] } } }
    ]);
    console.log(`Recruiter ${u.name} has ${pastWorkers.length} past workers`);
  }
  process.exit();
}).catch(console.error);

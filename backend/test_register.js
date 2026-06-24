const mongoose = require('mongoose');
const User = require('./models/User');
const authController = require('./controllers/authController');

const req = {
  body: {
    "name": "Ankit",
    "phone": "9999999988",
    "email": "ankit12@gmail.com",
    "password": "password123",
    "role": "recruiter",
    "aadhaarNumber": "616458484949"
  },
  t: (key) => key,
  app: { get: () => null }
};

const res = {
  status: function(s) { this.statusCode = s; return this; },
  json: function(data) { console.log("Status:", this.statusCode, data); }
};

async function run() {
  await mongoose.connect('mongodb://localhost:27017/kaamkaaz');
  
  await authController.register(req, res);
  process.exit(0);
}
run();

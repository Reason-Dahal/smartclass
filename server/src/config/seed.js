require('dotenv').config();
const dns = require('dns');
const mongoose = require('mongoose');
const User = require('../models/User');
const connectDB = require('./db');

dns.setServers(['8.8.8.8']);

const seedAdmin = async () => {
  await connectDB();

  const existingAdmin = await User.findOne({ role: 'admin' });
  if (existingAdmin) {
    console.log('Admin already exists');
    process.exit(0);
  }

  await User.create({
    name: 'Super Admin',
    email: 'admin@smartclass.com',
    password: 'Admin@123',
    role: 'admin',
    status: 'active',
    mustChangePassword: false,
  });

  console.log('Admin created successfully');
  console.log('Email: admin@smartclass.com');
  console.log('Password: Admin@123');
  process.exit(0);
};

seedAdmin();
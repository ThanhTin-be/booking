/**
 * Seed 1 tài khoản admin demo (không xóa users hiện tại).
 *
 * Chạy:
 *   node api/seedAdmin.js
 *
 * Hoặc:
 *   npm run seed:admin
 */

const bcrypt = require('bcryptjs');
const connectDB = require('../config/db');
const User = require('../models/User');
require('dotenv').config();

async function seedAdmin() {
  try {
    await connectDB();

    const email = process.env.DEMO_ADMIN_EMAIL || 'admin@gmail.com';
    const password = process.env.DEMO_ADMIN_PASSWORD || 'Admin@123456';

    const hashedPassword = await bcrypt.hash(password, 10);

    const admin = await User.findOneAndUpdate(
      { email },
      {
        $set: {
          fullName: 'Demo Admin',
          email,
          password: hashedPassword,
          role: 'admin',
          status: 'active',
          emailVerified: true,
          phone: '0900000000',
          avatar: 'https://i.pravatar.cc/150?img=12',
        },
      },
      { upsert: true, new: true }
    );

    console.log('✅ Seed admin demo thành công');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`Email:    ${admin.email}`);
    console.log(`Password: ${password}`);
    console.log(`Role:     ${admin.role}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    process.exit(0);
  } catch (error) {
    console.error('❌ Seed admin demo thất bại:', error.message);
    process.exit(1);
  }
}

seedAdmin();


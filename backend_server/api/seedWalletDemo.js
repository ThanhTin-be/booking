/**
 * Seed dữ liệu demo cho User + Wallet + Transaction.
 *
 * Chạy:
 *   node api/seedWalletDemo.js
 *
 * Hoặc (nếu có script):
 *   npm run seed:wallet-demo
 */
const bcrypt = require('bcryptjs');
const connectDB = require('../config/db');
const User = require('../models/User');
const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');

require('dotenv').config();

function formatCurrency(amount) {
  return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + 'đ';
}

async function upsertDemoUser({ fullName, email, password, phone, avatar, role = 'customer' }) {
  const hashedPassword = await bcrypt.hash(password, 10);
  return User.findOneAndUpdate(
    { email },
    {
      $set: {
        fullName,
        email,
        password: hashedPassword,
        role,
        status: 'active',
        emailVerified: true,
        phone,
        avatar,
      },
    },
    { upsert: true, new: true }
  );
}

async function seedWalletDemo() {
  try {
    await connectDB();

    const demoPassword = process.env.DEMO_USER_PASSWORD || 'User@123456';

    // 7 demo users (để có đủ các tier khác nhau)
    const demoUsersSpec = [
      { fullName: 'Demo User 1', email: 'demo_user1@gmail.com', phone: '0900000001', avatar: 'https://i.pravatar.cc/150?img=1', points: 0 },
      { fullName: 'Demo User 2', email: 'demo_user2@gmail.com', phone: '0900000002', avatar: 'https://i.pravatar.cc/150?img=2', points: 120 },
      { fullName: 'Demo User 3', email: 'demo_user3@gmail.com', phone: '0900000003', avatar: 'https://i.pravatar.cc/150?img=3', points: 520 },
      { fullName: 'Demo User 4', email: 'demo_user4@gmail.com', phone: '0900000004', avatar: 'https://i.pravatar.cc/150?img=4', points: 980 },
      { fullName: 'Demo User 5', email: 'demo_user5@gmail.com', phone: '0900000005', avatar: 'https://i.pravatar.cc/150?img=5', points: 1600 },
      { fullName: 'Demo User 6', email: 'demo_user6@gmail.com', phone: '0900000006', avatar: 'https://i.pravatar.cc/150?img=6', points: 2500 },
      { fullName: 'Demo User 7', email: 'demo_user7@gmail.com', phone: '0900000007', avatar: 'https://i.pravatar.cc/150?img=7', points: 3200 },
    ];

    const demoUsers = [];
    for (const spec of demoUsersSpec) {
      const user = await upsertDemoUser({
        fullName: spec.fullName,
        email: spec.email,
        password: demoPassword,
        phone: spec.phone,
        avatar: spec.avatar,
        role: 'customer',
      });
      demoUsers.push({ user, points: spec.points });
    }

    // Dọn dữ liệu ví/transaction của đúng nhóm demo users này (không ảnh hưởng user khác)
    const demoUserIds = demoUsers.map((x) => x.user._id);
    await Wallet.deleteMany({ user: { $in: demoUserIds } });
    await Transaction.deleteMany({ user: { $in: demoUserIds } });

    // Seed Wallet + 7 Transaction/user
    const now = Date.now();
    for (let idx = 0; idx < demoUsers.length; idx++) {
      const { user, points } = demoUsers[idx];

      const wallet = await Wallet.create({
        user: user._id,
        balance: 0,
        points,
      });

      // 7 giao dịch mẫu: 3 top_up, 3 payment, 1 refund
      const txSpecs = [
        { type: 'top_up', amount: 200000, description: `Nạp ví lần 1 +${formatCurrency(200000)}` },
        { type: 'top_up', amount: 150000, description: `Nạp ví lần 2 +${formatCurrency(150000)}` },
        { type: 'payment', amount: -80000, description: 'Thanh toán đặt sân (demo) #1' },
        { type: 'payment', amount: -120000, description: 'Thanh toán đặt sân (demo) #2' },
        { type: 'top_up', amount: 300000, description: `Nạp ví lần 3 +${formatCurrency(300000)}` },
        { type: 'payment', amount: -100000, description: 'Thanh toán đặt sân (demo) #3' },
        { type: 'refund', amount: 50000, description: `Hoàn tiền (demo) +${formatCurrency(50000)}` },
      ];

      for (let i = 0; i < txSpecs.length; i++) {
        const tx = txSpecs[i];

        wallet.balance += tx.amount;
        await wallet.save();

        await Transaction.create({
          wallet: wallet._id,
          user: user._id,
          type: tx.type,
          amount: tx.amount,
          description: tx.description,
          status: 'success',
          createdAt: new Date(now - (idx * 10 + i) * 60 * 60 * 1000),
          updatedAt: new Date(now - (idx * 10 + i) * 60 * 60 * 1000),
        });
      }
    }

    console.log('✅ Seed Wallet demo thành công');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`Password (all demo users): ${demoPassword}`);
    console.log('Demo emails:');
    for (const u of demoUsersSpec) console.log(`- ${u.email}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    process.exit(0);
  } catch (error) {
    console.error('❌ Seed Wallet demo thất bại:', error.message);
    process.exit(1);
  }
}

seedWalletDemo();


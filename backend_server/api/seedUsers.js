/**
 * File này là để seed (tạo) dữ liệu test cho database
 * Chạy: node api/seedUsers.js
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const connectDB = require('../config/db');
require('dotenv').config();

const seedUsers = async () => {
    try {
        // Kết nối database
        await connectDB();

        // Xóa tất cả users hiện tại (tùy chọn)
        await User.deleteMany({});
        console.log('✓ Đã xóa users cũ');

        // Tạo users test
        const hashedPassword = await bcrypt.hash('password123', 10);
        
        const users = [
            {
                fullName: 'Admin User',
                email: 'admin',
                password: hashedPassword,
                role: 'admin',
                phone: '0123456789',
                avatar: ''
            },
            {
                fullName: 'Nguyễn Văn A',
                email: 'user1',
                password: hashedPassword,
                role: 'customer',
                phone: '0987654321',
                avatar: ''
            },
            {
                fullName: 'Trần Thị B',
                email: 'user2',
                password: hashedPassword,
                role: 'customer',
                phone: '0912345678',
                avatar: ''
            }
        ];

        const createdUsers = await User.insertMany(users);
        console.log('✓ Tạo thành công ' + createdUsers.length + ' users');
        
        console.log('\n📝 Test Credentials:');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('Admin:');
        console.log('  Email: admin@example.com');
        console.log('  Password: password123');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('User 1:');
        console.log('  Email: user1@example.com');
        console.log('  Password: password123');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('User 2:');
        console.log('  Email: user2@example.com');
        console.log('  Password: password123');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        process.exit(0);
    } catch (error) {
        console.error('❌ Lỗi seed dữ liệu:', error.message);
        process.exit(1);
    }
};

seedUsers();

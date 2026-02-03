const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

async function seedUsers() {
    const users = [
        {
            fullName: 'Admin User',
            email: 'admin',
            password: '123',
            role: 'admin',
        },
        {
            fullName: 'Normal User',
            email: 'user',
            password: '123',
            role: 'customer',
        }
    ];

    for (const userData of users) {
        const exists = await User.findOne({ email: userData.email });
        if (!exists) {
            const hash = await bcrypt.hash(userData.password, 10);
            await User.create({ ...userData, password: hash });
            console.log(`Created user: ${userData.email}`);
        } else {
            console.log(`User already exists: ${userData.email}`);
        }
    }
    mongoose.disconnect();
}

mongoose.connect('mongodb://localhost:27017/booking', { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => seedUsers())
    .catch(err => console.error(err));

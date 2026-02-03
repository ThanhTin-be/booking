const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    fullName: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true }, // Nên dùng bcrypt để hash
    role: { type: String, enum: ['customer', 'admin'], default: 'customer' },
    avatar: { type: String, default: '' },
    phone: { type: String, default: '' },
    // Dùng để quản lý Refresh Token (Công nghệ mới để bảo mật mobile)
    refreshTokens: [{ type: String }],
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);
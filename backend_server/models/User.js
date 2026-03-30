const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    fullName: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: false }, // Không bắt buộc cho user đăng nhập Google
    role: { type: String, enum: ['customer', 'admin'], default: 'customer' },
    avatar: { type: String, default: '' },
    phone: { type: String, default: '' },
    // Google OAuth
    googleId: { type: String, default: null },
    // Facebook OAuth
    facebookId: { type: String, default: null },
    authProvider: { type: String, enum: ['local', 'google', 'facebook'], default: 'local' },
    // Email verification
    emailVerified: { type: Boolean, default: false },
    verificationCode: { type: String, default: null }, // Mã xác thực
    verificationCodeExpires: { type: Date, default: null }, // Hết hạn mã xác thực
    // Quên mật khẩu
    resetPasswordCode: { type: String, default: null },
    resetPasswordCodeExpires: { type: Date, default: null },
    // Thông tin mở rộng
    address: { type: String, default: '' },
    status: { type: String, enum: ['active', 'locked'], default: 'active' },
    // Dùng để quản lý Refresh Token (Công nghệ mới để bảo mật mobile)
    refreshTokens: [{ type: String }],
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);
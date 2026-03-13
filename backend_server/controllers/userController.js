const User = require('../models/User');
const Wallet = require('../models/Wallet');
const path = require('path');
const multer = require('multer');

// Cấu hình Multer upload avatar
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, path.join(__dirname, '../public/uploads'));
    },
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname);
        cb(null, `avatar_${req.user.id}_${Date.now()}${ext}`);
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|gif/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        if (extname && mimetype) {
            cb(null, true);
        } else {
            cb(new Error('Chỉ cho phép file ảnh (jpg, jpeg, png, gif)'));
        }
    }
});

// ============ CẬP NHẬT THÔNG TIN CÁ NHÂN ============
const updateProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const { fullName, phone, email, address } = req.body;

        const updateData = {};
        if (fullName) updateData.fullName = fullName;
        if (phone) updateData.phone = phone;
        if (address) updateData.address = address;

        // Nếu đổi email thì kiểm tra trùng
        if (email) {
            const existingUser = await User.findOne({ email, _id: { $ne: userId } });
            if (existingUser) {
                return res.status(400).json({ message: 'Email đã được sử dụng bởi tài khoản khác' });
            }
            updateData.email = email;
        }

        const updatedUser = await User.findByIdAndUpdate(
            userId,
            { $set: updateData },
            { new: true }
        ).select('-password -refreshTokens -verificationCode -verificationCodeExpires -resetPasswordCode -resetPasswordCodeExpires');

        if (!updatedUser) {
            return res.status(404).json({ message: 'Không tìm thấy user' });
        }

        return res.status(200).json({
            message: 'Cập nhật thông tin thành công',
            user: updatedUser
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ UPLOAD AVATAR ============
const uploadAvatar = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'Vui lòng chọn file ảnh' });
        }

        const avatarUrl = `/uploads/${req.file.filename}`;
        const updatedUser = await User.findByIdAndUpdate(
            req.user.id,
            { avatar: avatarUrl },
            { new: true }
        ).select('-password -refreshTokens');

        return res.status(200).json({
            message: 'Cập nhật avatar thành công',
            avatar: avatarUrl,
            user: updatedUser
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ LẤY THÔNG TIN VÍ ============
const getWalletInfo = async (req, res) => {
    try {
        const userId = req.user.id;

        // Tự tạo ví nếu chưa có
        let wallet = await Wallet.findOne({ user: userId });
        if (!wallet) {
            wallet = await Wallet.create({ user: userId, balance: 0, points: 0 });
        }

        const user = await User.findById(userId).select('role fullName');

        return res.status(200).json({
            message: 'Lấy thông tin ví thành công',
            wallet: {
                balance: wallet.balance,
                points: wallet.points,
                tier: wallet.tier,
                role: user?.role || 'customer'
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    updateProfile,
    uploadAvatar,
    getWalletInfo,
    upload // Export multer middleware
};


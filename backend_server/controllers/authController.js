const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const sendEmail = require('../utils/sendMail');

const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key';
const JWT_EXPIRE = '7d'; // Token hết hạn sau 7 ngày

// ============ ĐĂNG KÝ ============
const register = async (req, res) => {
    try {
        const { fullName, email, password, confirmPassword } = req.body;

        // Kiểm tra dữ liệu đầu vào
        if (!fullName || !email || !password || !confirmPassword) {
            return res.status(400).json({ 
                message: 'Vui lòng điền đầy đủ thông tin' 
            });
        }

        // Kiểm tra email đúng định dạng Gmail
        const gmailRegex = /^[a-zA-Z0-9._%+-]+@gmail\.com$/;
        if (!gmailRegex.test(email)) {
            return res.status(400).json({ 
                message: 'Email phải là Gmail (ví dụ: user@gmail.com)' 
            });
        }

        // Kiểm tra password khớp
        if (password !== confirmPassword) {
            return res.status(400).json({ 
                message: 'Mật khẩu không khớp' 
            });
        }

        // Kiểm tra email đã tồn tại
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ 
                message: 'Email đã được đăng ký' 
            });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Tạo mã xác thực (6 chữ số)
        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
        const verificationCodeExpires = new Date(Date.now() + 15 * 60 * 1000); // Hết hạn sau 15 phút

        console.log('🔑 Generated verification code:', verificationCode);
        console.log('🕐 Code expires at:', verificationCodeExpires);

        // Tạo user mới
        const newUser = new User({
            fullName,
            email,
            password: hashedPassword,
            role: 'customer',
            avatar: getRandomAvatar(),
            emailVerified: false,
            verificationCode,
            verificationCodeExpires
        });

        await newUser.save();

        // Gửi email xác thực
        const emailSubject = '🔐 Xác thực tài khoản Badminton App';
        const emailText = `Mã xác thực email của bạn là: ${verificationCode}\n\nMã này sẽ hết hạn sau 15 phút.\n\nNếu bạn không yêu cầu điều này, vui lòng bỏ qua email này.`;
        
        try {
            await sendEmail(email, emailSubject, emailText);
        } catch (emailError) {
            console.error('Lỗi gửi email:', emailError);
            // Vẫn cho phép đăng ký ngay cả khi gửi email thất bại
        }

        return res.status(201).json({
            message: 'Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản',
            user: {
                id: newUser._id,
                fullName: newUser.fullName,
                email: newUser.email,
                role: newUser.role,
                emailVerified: newUser.emailVerified
            }
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi server',
            error: error.message
        });
    }
};

// ============ ĐĂNG NHẬP ============
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Kiểm tra dữ liệu đầu vào
        if (!email || !password) {
            return res.status(400).json({ 
                message: 'Vui lòng nhập email và mật khẩu' 
            });
        }

        // Tìm user theo email
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({ 
                message: 'Email hoặc mật khẩu không đúng' 
            });
        }

        // Kiểm tra password
        const isPasswordCorrect = await bcrypt.compare(password, user.password);
        if (!isPasswordCorrect) {
            return res.status(401).json({ 
                message: 'Email hoặc mật khẩu không đúng' 
            });
        }

        // ✅ KIỂM TRA EMAIL ĐÃ XÁC THỰC CHƯA
        if (!user.emailVerified) {
            return res.status(400).json({ 
                message: 'Vui lòng xác thực email trước khi đăng nhập',
                requiresVerification: true,
                email: user.email
            });
        }

        // Tạo JWT Token
        const token = jwt.sign(
            { 
                id: user._id, 
                email: user.email, 
                fullName: user.fullName,
                role: user.role 
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRE }
        );

        // Lưu refresh token (nếu cần)
        user.refreshTokens.push(token);
        await user.save();

        return res.status(200).json({
            message: 'Đăng nhập thành công',
            token,
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email,
                role: user.role,
                emailVerified: user.emailVerified
            }
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi server',
            error: error.message
        });
    }
};

// ============ LẤY THÔNG TIN USER HIỆN TẠI ============
const getCurrentUser = async (req, res) => {
    try {
        const userId = req.user.id;
        const user = await User.findById(userId).select('-password -refreshTokens');

        if (!user) {
            return res.status(404).json({ 
                message: 'Không tìm thấy user' 
            });
        }

        return res.status(200).json({
            message: 'Lấy thông tin thành công',
            user
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi server',
            error: error.message
        });
    }
};

// ============ XÁC THỰC EMAIL ============
const verifyEmail = async (req, res) => {
    try {
        const { email } = req.body;
        const verificationCode = req.body.code || req.body.verificationCode || req.body.otp;

        console.log('📥 Request body:', req.body);

        // Kiểm tra dữ liệu đầu vào
        if (!email || !verificationCode) {
            return res.status(400).json({ 
                message: 'Vui lòng nhập email và mã xác thực' 
            });
        }

        // Tìm user
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ 
                message: 'Không tìm thấy tài khoản' 
            });
        }

        // Debug logging
        console.log('🔍 Debug verifyEmail:');
        console.log('Input code:', verificationCode);
        console.log('Stored code:', user.verificationCode);
        console.log('Code expires:', user.verificationCodeExpires);
        console.log('Current time:', new Date());
        console.log('Email verified status:', user.emailVerified);

        // Nếu user đã verified rồi
        if (user.emailVerified) {
            return res.status(400).json({ 
                message: 'Email đã được xác thực rồi' 
            });
        }

        // Kiểm tra xem có mã xác thực không
        if (!user.verificationCode) {
            return res.status(400).json({ 
                message: 'Không có mã xác thực. Vui lòng yêu cầu gửi lại mã' 
            });
        }

        // Kiểm tra mã có hết hạn không (kiểm tra trước để rõ ràng hơn)
        if (new Date() > user.verificationCodeExpires) {
            return res.status(400).json({ 
                message: 'Mã xác thực đã hết hạn. Vui lòng yêu cầu mã mới' 
            });
        }

        // Kiểm tra mã xác thực (trim và convert về string)
        const inputCode = verificationCode.toString().trim();
        const storedCode = user.verificationCode.toString().trim();
        
        if (inputCode !== storedCode) {
            return res.status(400).json({ 
                message: `Mã xác thực không đúng. Vui lòng kiểm tra lại email`,
                debug: {
                    inputCode: inputCode,
                    expectedLength: 6,
                    inputLength: inputCode.length
                }
            });
        }

        // Cập nhật trạng thái verified
        user.emailVerified = true;
        user.verificationCode = null;
        user.verificationCodeExpires = null;
        await user.save();

        return res.status(200).json({
            message: 'Xác thực email thành công! Bạn có thể đăng nhập ngay',
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email,
                emailVerified: user.emailVerified
            }
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi server',
            error: error.message
        });
    }
};

// ============ GỬI LẠI MÃ XÁC THỰC ============
const resendVerificationCode = async (req, res) => {
    try {
        const { email } = req.body;

        // Kiểm tra dữ liệu đầu vào
        if (!email) {
            return res.status(400).json({ 
                message: 'Vui lòng nhập email' 
            });
        }

        // Tìm user
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ 
                message: 'Không tìm thấy tài khoản' 
            });
        }

        // Nếu email đã verified thì không cần gửi lại
        if (user.emailVerified) {
            return res.status(400).json({ 
                message: 'Email đã được xác thực rồi' 
            });
        }

        // Tạo mã xác thực mới
        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
        const verificationCodeExpires = new Date(Date.now() + 15 * 60 * 1000);

        console.log('🔄 Resend verification code:', verificationCode, 'for email:', email);

        user.verificationCode = verificationCode;
        user.verificationCodeExpires = verificationCodeExpires;
        await user.save();

        // Gửi email
        const emailSubject = '🔐 Mã xác thực Badminton App (Gửi lại)';
        const emailText = `Mã xác thực email của bạn là: ${verificationCode}\n\nMã này sẽ hết hạn sau 15 phút.\n\nNếu bạn không yêu cầu điều này, vui lòng bỏ qua email này.`;
        
        try {
            await sendEmail(email, emailSubject, emailText);
        } catch (emailError) {
            console.error('Lỗi gửi email:', emailError);
        }

        return res.status(200).json({
            message: 'Mã xác thực mới đã được gửi đến email của bạn'
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi server',
            error: error.message
        });
    }
};

// ============ ĐĂNG XUẤT ============
const logout = async (req, res) => {
    try {
        const userId = req.user.id;
        const token = req.headers.authorization?.split(' ')[1];

        // Xóa token khỏi refreshTokens
        await User.findByIdAndUpdate(
            userId,
            { $pull: { refreshTokens: token } }
        );

        return res.status(200).json({
            message: 'Đăng xuất thành công'
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Lỗi server',
            error: error.message
        });
    }
};

// ============ HÀM HỖ TRỢ ============
// Hàm lấy avatar ngẫu nhiên
const getRandomAvatar = () => {
    try {
        const uploadsDir = path.join(__dirname, '../public/uploads');
        const files = fs.readdirSync(uploadsDir);
        const imageFiles = files.filter(file => /\.(png|jpg|jpeg|gif)$/i.test(file));
        
        if (imageFiles.length === 0) return '/uploads/default-avatar.png';
        
        const randomIndex = Math.floor(Math.random() * imageFiles.length);
        return `/uploads/${imageFiles[randomIndex]}`;
    } catch (error) {
        return '/uploads/default-avatar.png';
    }
};

// ============ QUÊN MẬT KHẨU ============
const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ message: 'Vui lòng nhập email' });
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'Không tìm thấy tài khoản với email này' });
        }

        // Tạo mã reset (6 chữ số)
        const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
        const resetCodeExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 phút

        user.resetPasswordCode = resetCode;
        user.resetPasswordCodeExpires = resetCodeExpires;
        await user.save();

        // Gửi email
        const emailSubject = '🔑 Đặt lại mật khẩu - Badminton App';
        const emailText = `Mã đặt lại mật khẩu của bạn là: ${resetCode}\n\nMã này sẽ hết hạn sau 15 phút.\n\nNếu bạn không yêu cầu điều này, vui lòng bỏ qua email này.`;

        try {
            await sendEmail(email, emailSubject, emailText);
        } catch (emailError) {
            console.error('Lỗi gửi email reset:', emailError);
        }

        return res.status(200).json({
            message: 'Mã đặt lại mật khẩu đã được gửi đến email của bạn'
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ ĐẶT LẠI MẬT KHẨU ============
const resetPassword = async (req, res) => {
    try {
        const { email, code, newPassword } = req.body;

        if (!email || !code || !newPassword) {
            return res.status(400).json({ message: 'Vui lòng nhập đầy đủ email, mã xác thực và mật khẩu mới' });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({ message: 'Mật khẩu mới phải có ít nhất 6 ký tự' });
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'Không tìm thấy tài khoản' });
        }

        // Kiểm tra mã reset
        if (!user.resetPasswordCode) {
            return res.status(400).json({ message: 'Không có yêu cầu đặt lại mật khẩu. Vui lòng gửi lại.' });
        }

        if (new Date() > user.resetPasswordCodeExpires) {
            return res.status(400).json({ message: 'Mã đã hết hạn. Vui lòng yêu cầu mã mới.' });
        }

        if (code.toString().trim() !== user.resetPasswordCode.toString().trim()) {
            return res.status(400).json({ message: 'Mã xác thực không đúng' });
        }

        // Hash mật khẩu mới
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        user.password = hashedPassword;
        user.resetPasswordCode = null;
        user.resetPasswordCodeExpires = null;
        await user.save();

        return res.status(200).json({
            message: 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.'
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    register,
    login,
    getCurrentUser,
    logout,
    verifyEmail,
    resendVerificationCode,
    forgotPassword,
    resetPassword
};

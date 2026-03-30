const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Route công khai
router.post('/register', authController.register);                  // Đăng ký
router.post('/login', authController.login);                        // Đăng nhập
router.post('/google', authController.googleLogin);                  // Đăng nhập bằng Google
router.post('/facebook', authController.facebookLogin);              // Đăng nhập bằng Facebook
router.post('/verify-email', authController.verifyEmail);           // Xác thực email
router.post('/resend-code', authController.resendVerificationCode); // Gửi lại mã xác thực
router.post('/forgot-password', authController.forgotPassword);     // Quên mật khẩu
router.post('/reset-password', authController.resetPassword);       // Đặt lại mật khẩu
router.get('/random-avatar', authController.getRandomAvatarEndpoint); // Lấy avatar ngẫu nhiên (cho guest)

// Route cần xác thực
router.get('/me', authMiddleware, authController.getCurrentUser);  // Lấy thông tin user hiện tại
router.post('/logout', authMiddleware, authController.logout);     // Đăng xuất

module.exports = router;

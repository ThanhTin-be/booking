const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Tất cả route đều cần xác thực
router.put('/profile', authMiddleware, userController.updateProfile);           // Cập nhật thông tin
router.post('/avatar', authMiddleware, userController.upload.single('avatar'), userController.uploadAvatar); // Upload avatar
router.get('/wallet', authMiddleware, userController.getWalletInfo);            // Lấy thông tin ví

module.exports = router;


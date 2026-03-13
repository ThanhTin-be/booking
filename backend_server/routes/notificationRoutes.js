const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Tất cả route đều cần xác thực
router.get('/', authMiddleware, notificationController.getNotifications);        // Danh sách thông báo
router.put('/read-all', authMiddleware, notificationController.markAllAsRead);   // Đọc tất cả (đặt trước /:id)
router.put('/:id/read', authMiddleware, notificationController.markAsRead);      // Đọc 1 thông báo

module.exports = router;


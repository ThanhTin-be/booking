const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Tất cả route đều cần xác thực
router.post('/hold', authMiddleware, bookingController.holdSlots);               // Giữ slot tạm thời
router.post('/', authMiddleware, bookingController.createBooking);              // Tạo booking
router.get('/', authMiddleware, bookingController.getMyBookings);               // Danh sách booking của tôi
router.get('/:id', authMiddleware, bookingController.getBookingDetail);         // Chi tiết booking
router.put('/:id/cancel', authMiddleware, bookingController.cancelBooking);     // Hủy booking

module.exports = router;


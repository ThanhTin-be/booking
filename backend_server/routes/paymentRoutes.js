const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Tất cả route đều cần xác thực
router.post('/', authMiddleware, paymentController.createPayment);              // Tạo thanh toán
router.put('/:id/confirm', authMiddleware, paymentController.confirmPayment);   // Xác nhận thanh toán
router.get('/:id/qr-code', authMiddleware, paymentController.generateQRCode);  // Tạo mã QR
router.get('/:id/status', authMiddleware, paymentController.checkPaymentStatus);// Kiểm tra trạng thái

module.exports = router;


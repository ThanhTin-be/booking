const express = require('express');
const router = express.Router();
const vnpayController = require('../controllers/vnpayController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Cần xác thực
router.post('/create-payment-url', authMiddleware, vnpayController.createBookingPaymentUrl);
router.post('/create-topup-url', authMiddleware, vnpayController.createTopupUrl);

// Public (VNPay server gọi)
router.get('/ipn', vnpayController.vnpayIPN);
router.get('/return', vnpayController.vnpayReturn);

// Mobile app gọi trực tiếp sau khi WebView detect return URL
router.post('/process-return', authMiddleware, vnpayController.processReturn);

module.exports = router;

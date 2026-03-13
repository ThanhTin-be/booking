const express = require('express');
const router = express.Router();
const discountController = require('../controllers/discountController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Tất cả route đều cần xác thực
router.get('/my-vouchers', authMiddleware, discountController.getMyVouchers);   // Voucher khả dụng
router.post('/apply', authMiddleware, discountController.applyDiscount);         // Áp dụng mã giảm giá

module.exports = router;


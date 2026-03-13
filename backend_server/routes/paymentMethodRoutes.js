const express = require('express');
const router = express.Router();
const paymentMethodController = require('../controllers/paymentMethodController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Tất cả route đều cần xác thực
router.get('/', authMiddleware, paymentMethodController.listPaymentMethods);        // Danh sách
router.post('/', authMiddleware, paymentMethodController.addPaymentMethod);         // Thêm mới
router.delete('/:id', authMiddleware, paymentMethodController.deletePaymentMethod); // Xóa

module.exports = router;


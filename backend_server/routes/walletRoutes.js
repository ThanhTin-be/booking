const express = require('express');
const router = express.Router();
const walletController = require('../controllers/walletController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Tất cả route đều cần xác thực
router.get('/balance', authMiddleware, walletController.getBalance);                // Số dư ví
router.post('/top-up', authMiddleware, walletController.topUp);                     // Nạp tiền
router.get('/transactions', authMiddleware, walletController.getTransactionHistory); // Lịch sử giao dịch

module.exports = router;


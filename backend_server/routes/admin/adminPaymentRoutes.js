const express = require('express');
const router = express.Router();

const adminPaymentController = require('../../controllers/admin/adminPaymentController');
const { authMiddleware, adminMiddleware } = require('../../middlewares/authMiddleware');

// Reports first (avoid conflict with "/:id")
router.get('/reports/transactions', authMiddleware, adminMiddleware, adminPaymentController.listTransactions);
router.get('/reports/wallets', authMiddleware, adminMiddleware, adminPaymentController.listWallets);

// Payments
router.get('/', authMiddleware, adminMiddleware, adminPaymentController.listPayments);
router.get('/:id', authMiddleware, adminMiddleware, adminPaymentController.getPaymentDetail);
router.patch('/:id/confirm', authMiddleware, adminMiddleware, adminPaymentController.confirmPayment);

module.exports = router;


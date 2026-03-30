const express = require('express');
const router = express.Router();

const adminDiscountController = require('../../controllers/admin/adminDiscountController');
const { authMiddleware, adminMiddleware } = require('../../middlewares/authMiddleware');

router.get('/', authMiddleware, adminMiddleware, adminDiscountController.listDiscounts);
router.post('/', authMiddleware, adminMiddleware, adminDiscountController.createDiscount);
router.patch('/:id', authMiddleware, adminMiddleware, adminDiscountController.updateDiscount);
router.patch('/:id/status', authMiddleware, adminMiddleware, adminDiscountController.updateDiscountStatus);

module.exports = router;


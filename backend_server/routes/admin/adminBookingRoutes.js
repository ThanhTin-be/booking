const express = require('express');
const router = express.Router();

const adminBookingController = require('../../controllers/admin/adminBookingController');
const { authMiddleware, adminMiddleware } = require('../../middlewares/authMiddleware');

router.get('/', authMiddleware, adminMiddleware, adminBookingController.listBookings);
router.get('/:id', authMiddleware, adminMiddleware, adminBookingController.getBookingDetail);
router.patch('/:id/status', authMiddleware, adminMiddleware, adminBookingController.updateBookingStatus);

module.exports = router;


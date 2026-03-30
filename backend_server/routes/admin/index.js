const express = require('express');

const adminDashboardRoutes = require('./adminDashboardRoutes');
const adminUserRoutes = require('./adminUserRoutes');
const adminCourtRoutes = require('./adminCourtRoutes');
const adminBookingRoutes = require('./adminBookingRoutes');
const adminPaymentRoutes = require('./adminPaymentRoutes');
const adminDiscountRoutes = require('./adminDiscountRoutes');
const adminWalletRoutes = require('./adminWalletRoutes');

const router = express.Router();

router.use('/dashboard', adminDashboardRoutes);
router.use('/users', adminUserRoutes);
router.use('/courts', adminCourtRoutes);
router.use('/bookings', adminBookingRoutes);
router.use('/payments', adminPaymentRoutes);
router.use('/discounts', adminDiscountRoutes);
router.use('/wallets', adminWalletRoutes);

module.exports = router;


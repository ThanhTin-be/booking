const express = require('express');
const router = express.Router();

const adminDashboardController = require('../../controllers/admin/adminDashboardController');
const { authMiddleware, adminMiddleware } = require('../../middlewares/authMiddleware');

router.get('/overview', authMiddleware, adminMiddleware, adminDashboardController.getOverview);

module.exports = router;


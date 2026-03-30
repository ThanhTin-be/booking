const express = require('express');
const router = express.Router();

const adminUserController = require('../../controllers/admin/adminUserController');
const { authMiddleware, adminMiddleware } = require('../../middlewares/authMiddleware');

router.get('/', authMiddleware, adminMiddleware, adminUserController.listUsers);
router.get('/:id', authMiddleware, adminMiddleware, adminUserController.getUserDetail);
router.patch('/:id/status', authMiddleware, adminMiddleware, adminUserController.updateUserStatus);
router.patch('/:id/role', authMiddleware, adminMiddleware, adminUserController.updateUserRole);

module.exports = router;


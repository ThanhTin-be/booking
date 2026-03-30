const express = require('express');
const router = express.Router();

const adminWalletController = require('../../controllers/admin/adminWalletController');
const { authMiddleware, adminMiddleware } = require('../../middlewares/authMiddleware');

router.get('/', authMiddleware, adminMiddleware, adminWalletController.listWallets);
router.patch('/:id', authMiddleware, adminMiddleware, adminWalletController.updateWallet);

module.exports = router;

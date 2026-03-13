const express = require('express');
const router = express.Router();
const wishlistController = require('../controllers/wishlistController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Tất cả route đều cần xác thực
router.get('/', authMiddleware, wishlistController.getWishlist);                // Danh sách yêu thích
router.post('/:courtId', authMiddleware, wishlistController.addCourt);          // Thêm vào yêu thích
router.delete('/:courtId', authMiddleware, wishlistController.removeCourt);     // Bỏ khỏi yêu thích

module.exports = router;


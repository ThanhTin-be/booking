const express = require('express');
const router = express.Router();
const courtController = require('../controllers/courtController');

// Route công khai (không cần đăng nhập để xem sân)
router.get('/', courtController.getAllCourts);                      // Danh sách sân
router.get('/search', courtController.searchCourts);                // Tìm kiếm sân
router.get('/nearby', courtController.getNearbyCourts);             // Sân gần đây
router.get('/:id', courtController.getCourtDetail);                 // Chi tiết sân
router.get('/:id/sub-courts', courtController.getSubCourts);       // Sân con
router.get('/:id/time-slots', courtController.getTimeSlots);       // Slot giờ theo ngày

module.exports = router;


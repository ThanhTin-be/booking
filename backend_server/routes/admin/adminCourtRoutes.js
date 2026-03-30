const express = require('express');
const router = express.Router();

const adminCourtController = require('../../controllers/admin/adminCourtController');
const { authMiddleware, adminMiddleware } = require('../../middlewares/authMiddleware');
const { courtUpload } = require('../../middlewares/upload');

// Courts
router.get('/', authMiddleware, adminMiddleware, adminCourtController.listCourts);
router.post('/', authMiddleware, adminMiddleware, adminCourtController.createCourt);
router.patch('/:id', authMiddleware, adminMiddleware, adminCourtController.updateCourt);
router.patch('/:id/status', authMiddleware, adminMiddleware, adminCourtController.updateCourtStatus);

// Upload court images (multipart/form-data)
router.post('/upload-images', authMiddleware, adminMiddleware,
    courtUpload.fields([
        { name: 'images', maxCount: 5 },
        { name: 'logo', maxCount: 1 }
    ]),
    adminCourtController.uploadCourtImages
);

// SubCourts
router.get('/:courtId/sub-courts', authMiddleware, adminMiddleware, adminCourtController.listSubCourts);
router.post('/:courtId/sub-courts', authMiddleware, adminMiddleware, adminCourtController.createSubCourt);
router.patch('/sub-courts/:id', authMiddleware, adminMiddleware, adminCourtController.updateSubCourt);
router.patch('/sub-courts/:id/status', authMiddleware, adminMiddleware, adminCourtController.updateSubCourtStatus);

// TimeSlots admin override
router.get('/:courtId/time-slots', authMiddleware, adminMiddleware, adminCourtController.getCourtTimeSlotsByDate);
router.post('/:courtId/time-slots/bulk', authMiddleware, adminMiddleware, adminCourtController.bulkGenerateTimeSlots);
router.patch('/time-slots/:id', authMiddleware, adminMiddleware, adminCourtController.updateTimeSlot);

module.exports = router;


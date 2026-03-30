const TimeSlot = require('../models/TimeSlot');
const Booking = require('../models/Booking');

const LOCK_TIMEOUT_MINUTES = 15;

/**
 * Giải phóng các slot bị lock quá thời gian cho phép.
 * Chạy định kỳ mỗi phút để kiểm tra và giải phóng slot hết hạn.
 */
async function releaseExpiredLockedSlots() {
    try {
        const cutoff = new Date(Date.now() - LOCK_TIMEOUT_MINUTES * 60 * 1000);

        // Tìm các slot locked quá hạn
        const expiredSlots = await TimeSlot.find({
            status: 'locked',
            lockedAt: { $lt: cutoff }
        });

        if (expiredSlots.length === 0) return;

        console.log(`[SlotCleanup] Tìm thấy ${expiredSlots.length} slot hết hạn lock. Đang giải phóng...`);

        // Lấy danh sách booking liên quan
        const bookingIds = [...new Set(
            expiredSlots
                .filter(s => s.booking)
                .map(s => s.booking.toString())
        )];

        // Giải phóng slots
        await TimeSlot.updateMany(
            { status: 'locked', lockedAt: { $lt: cutoff } },
            { $set: { status: 'available', booking: null, lockedAt: null } }
        );

        // Hủy các booking pending liên quan
        if (bookingIds.length > 0) {
            await Booking.updateMany(
                { _id: { $in: bookingIds }, status: 'pending' },
                { $set: { status: 'cancelled' } }
            );
            console.log(`[SlotCleanup] Đã hủy ${bookingIds.length} booking pending hết hạn.`);
        }

        console.log(`[SlotCleanup] Đã giải phóng ${expiredSlots.length} slot thành công.`);
    } catch (error) {
        console.error('[SlotCleanup] Lỗi:', error.message);
    }
}

/**
 * Bắt đầu chạy cleanup định kỳ mỗi phút
 */
function startSlotCleanupJob() {
    console.log(`[SlotCleanup] Khởi động job tự động giải phóng slot (timeout: ${LOCK_TIMEOUT_MINUTES} phút)`);
    
    // Chạy ngay lần đầu
    releaseExpiredLockedSlots();
    
    // Sau đó chạy mỗi phút
    setInterval(releaseExpiredLockedSlots, 60 * 1000);
}

module.exports = { releaseExpiredLockedSlots, startSlotCleanupJob };

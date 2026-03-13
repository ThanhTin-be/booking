const Booking = require('../models/Booking');
const Court = require('../models/Court');
const SubCourt = require('../models/SubCourt');
const TimeSlot = require('../models/TimeSlot');
const Notification = require('../models/Notification');
const Discount = require('../models/Discount');

// Hàm tạo mã booking tự động
async function generateBookingCode() {
    const lastBooking = await Booking.findOne().sort({ createdAt: -1 });
    if (!lastBooking || !lastBooking.bookingCode) {
        return 'BK1001';
    }
    const lastNumber = parseInt(lastBooking.bookingCode.replace('BK', ''));
    return `BK${lastNumber + 1}`;
}

// ============ TẠO ĐƠN ĐẶT SÂN ============
const createBooking = async (req, res) => {
    try {
        const userId = req.user.id;
        const {
            courtId,
            subCourtId,
            date,
            timeSlotIds, // Mảng ID các slot đã chọn
            paymentMethod,
            discountCode,
            contactName,
            contactPhone
        } = req.body;

        // Validate
        if (!courtId || !date || !timeSlotIds || timeSlotIds.length === 0) {
            return res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ thông tin đặt sân' });
        }

        // Kiểm tra sân tồn tại
        const court = await Court.findById(courtId);
        if (!court) {
            return res.status(404).json({ message: 'Không tìm thấy sân' });
        }

        // Kiểm tra các slot có sẵn không
        const slots = await TimeSlot.find({
            _id: { $in: timeSlotIds },
            status: 'available'
        }).sort({ startTime: 1 });

        if (slots.length !== timeSlotIds.length) {
            return res.status(400).json({
                message: 'Một hoặc nhiều khung giờ đã được đặt hoặc bị khóa. Vui lòng chọn lại.'
            });
        }

        // Tính giá
        let totalPrice = 0;
        for (const slot of slots) {
            totalPrice += slot.price;
        }

        // Áp dụng mã giảm giá nếu có
        let discountAmount = 0;
        let discountId = null;
        if (discountCode) {
            const discount = await Discount.findOne({
                code: discountCode.toUpperCase(),
                status: 'active',
                validTo: { $gte: new Date() },
                validFrom: { $lte: new Date() }
            });

            if (discount && discount.usedCount < discount.usageLimit && totalPrice >= discount.minOrderValue) {
                if (discount.discountType === 'percent') {
                    discountAmount = Math.floor(totalPrice * discount.discountValue / 100);
                    if (discount.maxDiscountAmount) {
                        discountAmount = Math.min(discountAmount, discount.maxDiscountAmount);
                    }
                } else {
                    discountAmount = discount.discountValue;
                }
                discountId = discount._id;
                discount.usedCount += 1;
                await discount.save();
            }
        }

        const finalPrice = Math.max(0, totalPrice - discountAmount);

        // Lấy startTime / endTime từ slots
        const startTime = slots[0].startTime;
        const endTime = slots[slots.length - 1].endTime;

        // Tạo booking
        const bookingCode = await generateBookingCode();
        const booking = new Booking({
            user: userId,
            court: courtId,
            subCourt: subCourtId || null,
            date,
            timeSlots: timeSlotIds,
            startTime,
            endTime,
            totalPrice,
            discountAmount,
            finalPrice,
            discount: discountId,
            paymentMethod: paymentMethod || 'cash',
            contactName: contactName || '',
            contactPhone: contactPhone || '',
            bookingCode,
            status: 'pending'
        });

        await booking.save();

        // Cập nhật trạng thái slots → booked
        await TimeSlot.updateMany(
            { _id: { $in: timeSlotIds } },
            { $set: { status: 'booked', booking: booking._id } }
        );

        // Tạo thông báo
        await Notification.create({
            user: userId,
            title: 'Đặt sân thành công',
            content: `Sân ${court.name} của bạn đã được đặt vào lúc ${startTime} ngày ${date}. Mã vé: ${bookingCode}`,
            type: 'booking',
            data: { bookingId: booking._id, bookingCode }
        });

        return res.status(201).json({
            message: 'Đặt sân thành công!',
            booking: {
                id: booking._id,
                bookingCode,
                courtName: court.name,
                date,
                startTime,
                endTime,
                totalPrice,
                discountAmount,
                finalPrice,
                paymentMethod: booking.paymentMethod,
                status: booking.status
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ LẤY DANH SÁCH BOOKING CỦA TÔI ============
const getMyBookings = async (req, res) => {
    try {
        const userId = req.user.id;
        const { status, page = 1, limit = 20 } = req.query;

        const filter = { user: userId };
        if (status) {
            // Map frontend status → backend status
            if (status === 'upcoming') filter.status = { $in: ['pending', 'confirmed'] };
            else if (status === 'completed') filter.status = 'completed';
            else if (status === 'cancelled') filter.status = 'cancelled';
            else filter.status = status;
        }

        const bookings = await Booking.find(filter)
            .populate('court', 'name address images category')
            .populate('subCourt', 'name')
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        const total = await Booking.countDocuments(filter);

        return res.status(200).json({
            message: 'Lấy danh sách vé thành công',
            bookings,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ LẤY CHI TIẾT 1 BOOKING ============
const getBookingDetail = async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id)
            .populate('court', 'name address images category pricePerHour')
            .populate('subCourt', 'name')
            .populate('timeSlots', 'startTime endTime price')
            .populate('discount', 'code description');

        if (!booking) {
            return res.status(404).json({ message: 'Không tìm thấy booking' });
        }

        // Kiểm tra quyền
        if (booking.user.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Bạn không có quyền xem booking này' });
        }

        return res.status(200).json({
            message: 'Lấy chi tiết booking thành công',
            booking
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ HỦY BOOKING ============
const cancelBooking = async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id);

        if (!booking) {
            return res.status(404).json({ message: 'Không tìm thấy booking' });
        }

        // Kiểm tra quyền
        if (booking.user.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Bạn không có quyền hủy booking này' });
        }

        // Chỉ hủy được khi đang pending hoặc confirmed
        if (!['pending', 'confirmed'].includes(booking.status)) {
            return res.status(400).json({ message: 'Không thể hủy booking này (trạng thái hiện tại: ' + booking.status + ')' });
        }

        // Cập nhật status
        booking.status = 'cancelled';
        await booking.save();

        // Giải phóng slot → available
        if (booking.timeSlots && booking.timeSlots.length > 0) {
            await TimeSlot.updateMany(
                { _id: { $in: booking.timeSlots } },
                { $set: { status: 'available', booking: null } }
            );
        }

        // Tạo thông báo
        await Notification.create({
            user: booking.user,
            title: 'Booking đã bị hủy',
            content: `Booking ${booking.bookingCode} đã được hủy thành công.`,
            type: 'booking',
            data: { bookingId: booking._id }
        });

        return res.status(200).json({
            message: 'Hủy booking thành công',
            booking: {
                id: booking._id,
                bookingCode: booking.bookingCode,
                status: booking.status
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    createBooking,
    getMyBookings,
    getBookingDetail,
    cancelBooking
};


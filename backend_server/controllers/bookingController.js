const mongoose = require('mongoose');
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

// ============ TẠO ĐƠN ĐẶT SÂN (có Transaction chống race condition) ============
const createBooking = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

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
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ thông tin đặt sân' });
        }

        // Kiểm tra sân tồn tại
        const court = await Court.findById(courtId).session(session);
        if (!court) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({ message: 'Không tìm thấy sân' });
        }

        // ===== Kiểm tra khung giờ đã qua (chỉ cho ngày hôm nay) =====
        const vnOptions = { timeZone: 'Asia/Ho_Chi_Minh' };
        const todayStr = new Date().toLocaleDateString('sv-SE', vnOptions);
        if (date === todayStr) {
            const nowTime = new Date().toLocaleTimeString('en-GB', { ...vnOptions, hour: '2-digit', minute: '2-digit', hour12: false });
            const slotsToCheck = await TimeSlot.find({ _id: { $in: timeSlotIds } }).session(session);
            const pastSlot = slotsToCheck.find(s => s.startTime <= nowTime);
            if (pastSlot) {
                await session.abortTransaction();
                session.endSession();
                return res.status(400).json({ message: 'Khung giờ đã qua, vui lòng chọn khung giờ khác.' });
            }
        }

        // ===== ATOMIC LOCK: Dùng findOneAndUpdate để lock từng slot =====
        // Chỉ lock được slot có status = 'available'
        const lockedSlots = [];
        for (const slotId of timeSlotIds) {
            const lockedSlot = await TimeSlot.findOneAndUpdate(
                { _id: slotId, status: 'available' },
                { $set: { status: 'locked', lockedAt: new Date() } },
                { new: true, session }
            );

            if (!lockedSlot) {
                // Slot đã bị đặt/khóa bởi người khác → rollback tất cả
                await session.abortTransaction();
                session.endSession();
                return res.status(409).json({
                    message: 'Một hoặc nhiều khung giờ đã được đặt hoặc đang được giữ. Vui lòng chọn lại.'
                });
            }
            lockedSlots.push(lockedSlot);
        }

        // Sắp xếp theo startTime
        lockedSlots.sort((a, b) => a.startTime.localeCompare(b.startTime));

        // Tính giá
        let totalPrice = 0;
        for (const slot of lockedSlots) {
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
            }).session(session);

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
                await discount.save({ session });
            }
        }

        const finalPrice = Math.max(0, totalPrice - discountAmount);

        // Lấy startTime / endTime từ slots
        const startTime = lockedSlots[0].startTime;
        const endTime = lockedSlots[lockedSlots.length - 1].endTime;

        // Xác định status ban đầu: cash → confirmed ngay, còn lại → pending (chờ thanh toán)
        const effectivePaymentMethod = paymentMethod || 'cash';
        const initialStatus = (effectivePaymentMethod === 'cash') ? 'confirmed' : 'pending';

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
            paymentMethod: effectivePaymentMethod,
            contactName: contactName || '',
            contactPhone: contactPhone || '',
            bookingCode,
            status: initialStatus
        });

        await booking.save({ session });

        // Cập nhật booking reference trong các slot
        if (effectivePaymentMethod === 'cash') {
            // Cash → xác nhận ngay: slot chuyển thành booked
            await TimeSlot.updateMany(
                { _id: { $in: timeSlotIds } },
                { $set: { booking: booking._id, status: 'booked', lockedAt: null } },
                { session }
            );
        } else {
            // Các phương thức khác: giữ slot locked, chờ thanh toán
            await TimeSlot.updateMany(
                { _id: { $in: timeSlotIds } },
                { $set: { booking: booking._id } },
                { session }
            );
        }

        // Commit transaction thành công
        await session.commitTransaction();
        session.endSession();

        // Tạo thông báo (ngoài transaction, không cần rollback nếu lỗi)
        const notifContent = (effectivePaymentMethod === 'cash')
            ? `Sân ${court.name} đã được đặt thành công vào lúc ${startTime} ngày ${date}. Mã vé: ${bookingCode}. Thanh toán tại quầy khi đến sân.`
            : `Sân ${court.name} đang được giữ cho bạn. Vui lòng thanh toán trong 15 phút. Mã vé: ${bookingCode}.`;
        try {
            await Notification.create({
                user: userId,
                title: effectivePaymentMethod === 'cash' ? 'Đặt sân thành công' : 'Đang giữ sân cho bạn',
                content: notifContent,
                type: 'booking',
                data: { bookingId: booking._id, bookingCode }
            });
        } catch (notifErr) {
            console.error('Notification error:', notifErr.message);
        }

        const responseMsg = (effectivePaymentMethod === 'cash')
            ? 'Đặt sân thành công!'
            : 'Đặt sân thành công! Vui lòng thanh toán trong 15 phút.';
        return res.status(201).json({
            message: responseMsg,
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
        await session.abortTransaction();
        session.endSession();
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ LẤY DANH SÁCH BOOKING CỦA TÔI ============
const getMyBookings = async (req, res) => {
    try {
        const userId = req.user.id;
        const { status, page = 1, limit = 20 } = req.query;

        // Auto-complete: chuyển booking đã qua thời gian sang "completed"
        const now = new Date();
        // Dùng timezone Việt Nam vì booking lưu date/time theo giờ local
        const vnOptions = { timeZone: 'Asia/Ho_Chi_Minh' };
        const todayStr = now.toLocaleDateString('sv-SE', vnOptions); // "YYYY-MM-DD" (sv-SE format)
        const nowTime = now.toLocaleTimeString('en-GB', { ...vnOptions, hour: '2-digit', minute: '2-digit', hour12: false }); // "HH:mm"

        await Booking.updateMany(
            {
                user: userId,
                status: { $in: ['pending', 'confirmed'] },
                $or: [
                    { date: { $lt: todayStr } },
                    { date: todayStr, endTime: { $lte: nowTime } }
                ]
            },
            { $set: { status: 'completed' } }
        );

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
            .populate('timeSlots', 'startTime endTime price')
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
            .populate({ path: 'timeSlots', select: 'startTime endTime price subCourt', populate: { path: 'subCourt', select: 'name' } })
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

        // Giải phóng slot → available (cả locked lẫn booked đều trả về available)
        if (booking.timeSlots && booking.timeSlots.length > 0) {
            await TimeSlot.updateMany(
                { _id: { $in: booking.timeSlots } },
                { $set: { status: 'available', booking: null, lockedAt: null } }
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

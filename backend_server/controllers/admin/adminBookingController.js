const mongoose = require('mongoose');
const Booking = require('../../models/Booking');
const TimeSlot = require('../../models/TimeSlot');
const Notification = require('../../models/Notification');
const Wallet = require('../../models/Wallet');
const Payment = require('../../models/Payment');
const Transaction = require('../../models/Transaction');
const { parsePagination, parseSort } = require('../../utils/pagination');
const { buildRegexQuery } = require('../../utils/query');

const listBookings = async (req, res) => {
    try {
        const { status, q, courtId, userId, from, to } = req.query;
        const { page, limit, skip } = parsePagination(req.query);
        const sort = parseSort(req.query.sort, { createdAt: -1 });

        const filter = {};
        if (status) filter.status = status;
        if (courtId) filter.court = courtId;
        if (userId) filter.user = userId;

        if (from || to) {
            filter.createdAt = {};
            if (from) filter.createdAt.$gte = new Date(`${from}T00:00:00.000Z`);
            if (to) filter.createdAt.$lte = new Date(`${to}T23:59:59.999Z`);
        }

        const rx = buildRegexQuery(q);
        if (rx) {
            // bookingCode/search by contactName/contactPhone
            filter.$or = [
                { bookingCode: rx },
                { contactName: rx },
                { contactPhone: rx }
            ];
        }

        const [bookings, total] = await Promise.all([
            Booking.find(filter)
                .populate('court', 'name address category')
                .populate('user', 'fullName email phone role status')
                .sort(sort)
                .skip(skip)
                .limit(limit),
            Booking.countDocuments(filter)
        ]);

        const userIds = bookings
            .map((b) => (b.user ? b.user._id || b.user : null))
            .filter((id) => !!id);

        const walletDocs = await Wallet.find({ user: { $in: userIds } }).select('user balance points tier');
        const walletMap = walletDocs.reduce((acc, w) => {
            acc[w.user.toString()] = {
                balance: w.balance,
                points: w.points,
                tier: w.tier
            };
            return acc;
        }, {});

        const bookingsWithWallet = bookings.map((b) => {
            const bookingObj = b.toObject();
            const userId = bookingObj.user?._id?.toString();

            if (userId) {
                bookingObj.user = {
                    ...bookingObj.user,
                    wallet: walletMap[userId] || {
                        balance: 0,
                        points: 0,
                        tier: 'member'
                    }
                };
            }

            return bookingObj;
        });

        return res.status(200).json({
            message: 'Admin list bookings',
            bookings: bookingsWithWallet,
            pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const getBookingDetail = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Booking id không hợp lệ' });
        }

        const booking = await Booking.findById(id)
            .populate('court', 'name address images category pricePerHour pricePerSlot openTime closeTime')
            .populate('subCourt', 'name type pricePerSlot status')
            .populate('timeSlots', 'date startTime endTime price status')
            .populate('discount', 'code description discountType discountValue')
            .populate('user', 'fullName email phone role status');

        if (!booking) return res.status(404).json({ message: 'Không tìm thấy booking' });

        let wallet = null;
        if (booking.user) {
            wallet = await Wallet.findOne({ user: booking.user._id }).select('balance points tier');
        }

        // Lấy payment history liên quan
        const payments = await Payment.find({ booking: booking._id })
            .sort({ createdAt: -1 });

        const bookingObj = booking.toObject();
        if (bookingObj.user) {
            bookingObj.user = {
                ...bookingObj.user,
                wallet: wallet
                    ? {
                          balance: wallet.balance,
                          points: wallet.points,
                          tier: wallet.tier
                      }
                    : {
                          balance: 0,
                          points: 0,
                          tier: 'member'
                      }
            };
        }

        // Thêm payment history vào response
        bookingObj.payments = payments;

        return res.status(200).json({ message: 'Admin booking detail', booking: bookingObj });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateBookingStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Booking id không hợp lệ' });
        }
        if (!['pending', 'confirmed', 'cancelled', 'completed'].includes(status)) {
            return res.status(400).json({ message: "status phải là 'pending'|'confirmed'|'cancelled'|'completed'" });
        }

        const booking = await Booking.findById(id);
        if (!booking) return res.status(404).json({ message: 'Không tìm thấy booking' });

        const prevStatus = booking.status;
        booking.status = status;
        await booking.save();

        // If completed -> award points based on finalPrice (1 point per 1.000đ spent)
        if (status === 'completed' && prevStatus !== 'completed') {
            const earnedPoints = Math.floor((booking.finalPrice || 0) / 1000);

            if (earnedPoints > 0) {
                const wallet = await Wallet.findOneAndUpdate(
                    { user: booking.user },
                    { $inc: { points: earnedPoints } },
                    { new: true, upsert: true, setDefaultsOnInsert: true }
                );

                // Ensure tier is consistent even when using findOneAndUpdate
                await wallet.save();
            }
        }

        // If cancelled -> release slots (only if were booked)
        if (status === 'cancelled' && prevStatus !== 'cancelled') {
            if (booking.timeSlots?.length) {
                await TimeSlot.updateMany(
                    { _id: { $in: booking.timeSlots } },
                    { $set: { status: 'available', booking: null } }
                );
            }

            // Best-effort refund if paid by wallet and payment was completed
            try {
                const payment = await Payment.findOne({ booking: booking._id, status: 'completed', method: 'wallet' });
                if (payment) {
                    const wallet = await Wallet.findOneAndUpdate(
                        { user: booking.user },
                        { $inc: { balance: payment.amount } },
                        { new: true, upsert: true, setDefaultsOnInsert: true }
                    );

                    await Transaction.create({
                        wallet: wallet._id,
                        user: booking.user,
                        type: 'refund',
                        amount: payment.amount,
                        description: `Refund booking ${booking.bookingCode}`,
                        relatedBooking: booking._id,
                        status: 'success'
                    });

                    payment.status = 'refunded';
                    await payment.save();
                }
            } catch (_) {
                // Refund is best-effort
            }
        }

        // Notify user
        try {
            await Notification.create({
                user: booking.user,
                title: 'Cập nhật trạng thái booking',
                content: `Booking ${booking.bookingCode} đã được cập nhật trạng thái: ${status}`,
                type: 'booking',
                data: { bookingId: booking._id, bookingCode: booking.bookingCode, status }
            });
        } catch (_) {
            // Notification is best-effort
        }

        return res.status(200).json({ message: 'Cập nhật trạng thái booking thành công', booking });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    listBookings,
    getBookingDetail,
    updateBookingStatus
};


const mongoose = require('mongoose');
const Payment = require('../../models/Payment');
const Booking = require('../../models/Booking');
const Wallet = require('../../models/Wallet');
const Transaction = require('../../models/Transaction');
const Notification = require('../../models/Notification');
const { parsePagination, parseSort } = require('../../utils/pagination');

const listPayments = async (req, res) => {
    try {
        const { status, method, from, to } = req.query;
        const { page, limit, skip } = parsePagination(req.query);
        const sort = parseSort(req.query.sort, { createdAt: -1 });

        const filter = {};
        if (status) filter.status = status;
        if (method) filter.method = method;
        if (from || to) {
            filter.createdAt = {};
            if (from) filter.createdAt.$gte = new Date(`${from}T00:00:00.000Z`);
            if (to) filter.createdAt.$lte = new Date(`${to}T23:59:59.999Z`);
        }

        const [payments, total] = await Promise.all([
            Payment.find(filter)
                .populate('user', 'fullName email phone role status')
                .populate('booking', 'bookingCode status finalPrice court date startTime endTime')
                .sort(sort)
                .skip(skip)
                .limit(limit),
            Payment.countDocuments(filter)
        ]);

        return res.status(200).json({
            message: 'Admin list payments',
            payments,
            pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const getPaymentDetail = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Payment id không hợp lệ' });
        }
        const payment = await Payment.findById(id)
            .populate('user', 'fullName email phone role status')
            .populate({
                path: 'booking',
                populate: [
                    { path: 'court', select: 'name address category' }
                ]
            });
        if (!payment) return res.status(404).json({ message: 'Không tìm thấy payment' });

        return res.status(200).json({ message: 'Admin payment detail', payment });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const confirmPayment = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Payment id không hợp lệ' });
        }

        const payment = await Payment.findById(id);
        if (!payment) return res.status(404).json({ message: 'Không tìm thấy payment' });
        if (payment.status === 'completed') {
            return res.status(400).json({ message: 'Payment đã completed trước đó' });
        }

        // If wallet method, ensure wallet has enough and deduct from the payment.user
        if (payment.method === 'wallet') {
            const wallet = await Wallet.findOne({ user: payment.user });
            if (!wallet) return res.status(400).json({ message: 'User chưa có ví' });
            if (wallet.balance < payment.amount) return res.status(400).json({ message: 'Số dư ví không đủ' });

            wallet.balance -= payment.amount;
            await wallet.save();

            await Transaction.create({
                wallet: wallet._id,
                user: payment.user,
                type: 'payment',
                amount: -payment.amount,
                description: `Admin confirm payment ${payment.transactionId || payment._id}`,
                relatedBooking: payment.booking,
                status: 'success'
            });
        }

        payment.status = 'completed';
        payment.paidAt = new Date();
        await payment.save();

        await Booking.findByIdAndUpdate(payment.booking, { status: 'confirmed' });

        try {
            await Notification.create({
                user: payment.user,
                title: 'Thanh toán thành công',
                content: `Thanh toán ${payment.amount} qua ${payment.method} đã được xác nhận.`,
                type: 'payment',
                data: { paymentId: payment._id, bookingId: payment.booking }
            });
        } catch (_) {}

        return res.status(200).json({ message: 'Admin confirm payment thành công', payment });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const listTransactions = async (req, res) => {
    try {
        const { type, userId, from, to } = req.query;
        const { page, limit, skip } = parsePagination(req.query);
        const sort = parseSort(req.query.sort, { createdAt: -1 });

        const filter = {};
        if (type) filter.type = type;
        if (userId) filter.user = userId;
        if (from || to) {
            filter.createdAt = {};
            if (from) filter.createdAt.$gte = new Date(`${from}T00:00:00.000Z`);
            if (to) filter.createdAt.$lte = new Date(`${to}T23:59:59.999Z`);
        }

        const [transactions, total] = await Promise.all([
            Transaction.find(filter)
                .populate('user', 'fullName email phone role status')
                .populate('relatedBooking', 'bookingCode status finalPrice')
                .sort(sort)
                .skip(skip)
                .limit(limit),
            Transaction.countDocuments(filter)
        ]);

        return res.status(200).json({
            message: 'Admin list transactions',
            transactions,
            pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const listWallets = async (req, res) => {
    try {
        const { userId } = req.query;
        const { page, limit, skip } = parsePagination(req.query);
        const sort = parseSort(req.query.sort, { updatedAt: -1 });

        const filter = {};
        if (userId) filter.user = userId;

        const [wallets, total] = await Promise.all([
            Wallet.find(filter)
                .populate('user', 'fullName email phone role status')
                .sort(sort)
                .skip(skip)
                .limit(limit),
            Wallet.countDocuments(filter)
        ]);

        return res.status(200).json({
            message: 'Admin list wallets',
            wallets,
            pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    listPayments,
    getPaymentDetail,
    confirmPayment,
    listTransactions,
    listWallets
};


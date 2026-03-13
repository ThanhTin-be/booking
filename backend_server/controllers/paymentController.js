const Payment = require('../models/Payment');
const Booking = require('../models/Booking');
const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const Notification = require('../models/Notification');
const QRCode = require('qrcode');

// ============ TẠO YÊU CẦU THANH TOÁN ============
const createPayment = async (req, res) => {
    try {
        const userId = req.user.id;
        const { bookingId, method } = req.body;

        if (!bookingId) {
            return res.status(400).json({ message: 'Vui lòng cung cấp bookingId' });
        }

        // Kiểm tra booking
        const booking = await Booking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ message: 'Không tìm thấy booking' });
        }

        if (booking.user.toString() !== userId) {
            return res.status(403).json({ message: 'Không có quyền thanh toán booking này' });
        }

        // Kiểm tra đã có payment chưa
        const existingPayment = await Payment.findOne({ booking: bookingId, status: { $ne: 'failed' } });
        if (existingPayment) {
            return res.status(400).json({
                message: 'Booking này đã có yêu cầu thanh toán',
                payment: existingPayment
            });
        }

        // Tạo mã giao dịch
        const transactionId = `PAY${Date.now()}${Math.floor(Math.random() * 1000)}`;

        // Tạo QR data
        const qrData = JSON.stringify({
            transactionId,
            amount: booking.finalPrice,
            bookingCode: booking.bookingCode,
            method: method || 'bank'
        });

        const payment = await Payment.create({
            booking: bookingId,
            user: userId,
            amount: booking.finalPrice,
            method: method || 'cash',
            status: 'pending',
            transactionId,
            qrCodeData: qrData
        });

        return res.status(201).json({
            message: 'Tạo yêu cầu thanh toán thành công',
            payment: {
                id: payment._id,
                amount: payment.amount,
                method: payment.method,
                status: payment.status,
                transactionId: payment.transactionId
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ XÁC NHẬN THANH TOÁN ============
const confirmPayment = async (req, res) => {
    try {
        const { id } = req.params; // paymentId
        const userId = req.user.id;

        const payment = await Payment.findById(id);
        if (!payment) {
            return res.status(404).json({ message: 'Không tìm thấy thanh toán' });
        }

        if (payment.status === 'completed') {
            return res.status(400).json({ message: 'Thanh toán đã được xác nhận trước đó' });
        }

        // Nếu thanh toán bằng ví → trừ tiền ví
        if (payment.method === 'wallet') {
            let wallet = await Wallet.findOne({ user: userId });
            if (!wallet) {
                return res.status(400).json({ message: 'Bạn chưa có ví. Vui lòng nạp tiền trước.' });
            }
            if (wallet.balance < payment.amount) {
                return res.status(400).json({ message: 'Số dư ví không đủ' });
            }

            wallet.balance -= payment.amount;
            await wallet.save();

            // Tạo giao dịch trừ tiền
            await Transaction.create({
                wallet: wallet._id,
                user: userId,
                type: 'payment',
                amount: -payment.amount,
                description: `Thanh toán booking ${payment.transactionId}`,
                relatedBooking: payment.booking
            });
        }

        // Cập nhật payment
        payment.status = 'completed';
        payment.paidAt = new Date();
        await payment.save();

        // Cập nhật booking status → confirmed
        await Booking.findByIdAndUpdate(payment.booking, { status: 'confirmed' });

        // Tạo thông báo
        await Notification.create({
            user: userId,
            title: 'Thanh toán thành công',
            content: `Thanh toán ${formatCurrency(payment.amount)} qua ${payment.method} thành công.`,
            type: 'payment',
            data: { paymentId: payment._id, bookingId: payment.booking }
        });

        return res.status(200).json({
            message: 'Xác nhận thanh toán thành công',
            payment: {
                id: payment._id,
                status: payment.status,
                paidAt: payment.paidAt
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ TẠO MÃ QR THANH TOÁN ============
const generateQRCode = async (req, res) => {
    try {
        const { id } = req.params; // paymentId

        const payment = await Payment.findById(id).populate('booking', 'bookingCode');
        if (!payment) {
            return res.status(404).json({ message: 'Không tìm thấy thanh toán' });
        }

        const qrContent = `DATSAN_${payment.transactionId}_${payment.amount}`;

        // Tạo QR code dưới dạng base64
        const qrBase64 = await QRCode.toDataURL(qrContent, {
            width: 300,
            margin: 2,
            color: { dark: '#000000', light: '#ffffff' }
        });

        return res.status(200).json({
            message: 'Tạo mã QR thành công',
            qrCode: qrBase64,
            paymentInfo: {
                amount: payment.amount,
                transactionId: payment.transactionId,
                method: payment.method,
                content: `DATSAN${payment.transactionId.slice(-6)}`,
                bookingCode: payment.booking?.bookingCode
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ KIỂM TRA TRẠNG THÁI THANH TOÁN ============
const checkPaymentStatus = async (req, res) => {
    try {
        const { id } = req.params; // paymentId

        const payment = await Payment.findById(id)
            .populate('booking', 'bookingCode status');

        if (!payment) {
            return res.status(404).json({ message: 'Không tìm thấy thanh toán' });
        }

        return res.status(200).json({
            message: 'Lấy trạng thái thanh toán thành công',
            payment: {
                id: payment._id,
                amount: payment.amount,
                method: payment.method,
                status: payment.status,
                transactionId: payment.transactionId,
                paidAt: payment.paidAt,
                bookingCode: payment.booking?.bookingCode,
                bookingStatus: payment.booking?.status
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// Helper format tiền
function formatCurrency(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + 'đ';
}

module.exports = {
    createPayment,
    confirmPayment,
    generateQRCode,
    checkPaymentStatus
};


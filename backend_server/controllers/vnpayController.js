const mongoose = require('mongoose');
const Payment = require('../models/Payment');
const Booking = require('../models/Booking');
const TimeSlot = require('../models/TimeSlot');
const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const Notification = require('../models/Notification');
const { createPaymentUrl, verifyChecksum } = require('../utils/vnpay');

// Helper format tiền
function formatCurrency(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + 'đ';
}

// ============ TẠO URL THANH TOÁN VNPAY CHO BOOKING ============
const createBookingPaymentUrl = async (req, res) => {
    try {
        const userId = req.user.id;
        const { bookingId } = req.body;

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

        // Kiểm tra đã có payment thành công chưa
        const existingPayment = await Payment.findOne({
            booking: bookingId,
            status: 'completed'
        });
        if (existingPayment) {
            return res.status(400).json({ message: 'Booking này đã được thanh toán' });
        }

        // Tìm hoặc tạo payment pending
        let payment = await Payment.findOne({
            booking: bookingId,
            method: 'vnpay',
            status: 'pending'
        });

        if (!payment) {
            const transactionId = `VNPAY${Date.now()}${Math.floor(Math.random() * 1000)}`;
            payment = await Payment.create({
                booking: bookingId,
                user: userId,
                amount: booking.finalPrice,
                method: 'vnpay',
                status: 'pending',
                transactionId,
            });
        }

        // Lấy IP client
        const ipAddr = req.headers['x-forwarded-for']
            || req.connection?.remoteAddress
            || req.socket?.remoteAddress
            || '127.0.0.1';

        const ngrokUrl = process.env.NGROK_URL || `http://localhost:${process.env.PORT || 3000}`;
        const returnUrl = `${ngrokUrl}/api/vnpay/return`;

        const paymentUrl = createPaymentUrl({
            amount: booking.finalPrice,
            orderId: payment.transactionId,
            orderInfo: `Thanh toan dat san ${booking.bookingCode || bookingId}`,
            ipAddr: ipAddr.split(',')[0].trim(),
            returnUrl,
        });

        return res.status(200).json({
            message: 'Tạo URL thanh toán thành công',
            paymentUrl,
            paymentId: payment._id,
            transactionId: payment.transactionId,
        });
    } catch (error) {
        console.error('createBookingPaymentUrl error:', error);
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ TẠO URL NẠP TIỀN VÍ QUA VNPAY ============
const createTopupUrl = async (req, res) => {
    try {
        const userId = req.user.id;
        const { amount } = req.body;

        if (!amount || amount <= 0) {
            return res.status(400).json({ message: 'Số tiền nạp phải lớn hơn 0' });
        }
        if (amount < 10000) {
            return res.status(400).json({ message: 'Số tiền nạp tối thiểu 10.000đ' });
        }

        // Tìm hoặc tạo ví
        let wallet = await Wallet.findOne({ user: userId });
        if (!wallet) {
            wallet = await Wallet.create({ user: userId, balance: 0, points: 0 });
        }

        // Tạo mã giao dịch unique
        const vnpTxnRef = `TOPUP${Date.now()}${Math.floor(Math.random() * 1000)}`;

        // Tạo transaction pending
        const transaction = await Transaction.create({
            wallet: wallet._id,
            user: userId,
            type: 'vnpay_topup',
            amount: amount,
            description: `Nạp tiền ví qua VNPay +${formatCurrency(amount)}`,
            status: 'pending',
            vnpTxnRef: vnpTxnRef,
        });

        // Lấy IP client
        const ipAddr = req.headers['x-forwarded-for']
            || req.connection?.remoteAddress
            || req.socket?.remoteAddress
            || '127.0.0.1';

        const ngrokUrl = process.env.NGROK_URL || `http://localhost:${process.env.PORT || 3000}`;
        const returnUrl = `${ngrokUrl}/api/vnpay/return`;

        const paymentUrl = createPaymentUrl({
            amount: amount,
            orderId: vnpTxnRef,
            orderInfo: `Nap tien vi ${amount} VND`,
            ipAddr: ipAddr.split(',')[0].trim(),
            returnUrl,
        });

        return res.status(200).json({
            message: 'Tạo URL nạp tiền thành công',
            paymentUrl,
            transactionId: transaction._id,
            vnpTxnRef,
        });
    } catch (error) {
        console.error('createTopupUrl error:', error);
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ IPN URL - VNPAY GỌI LẠI (SERVER-TO-SERVER) ============
const vnpayIPN = async (req, res) => {
    try {
        const vnp_Params = req.query;

        // Xác thực checksum
        if (!verifyChecksum(vnp_Params)) {
            console.log('VNPay IPN: Invalid checksum');
            return res.status(200).json({ RspCode: '97', Message: 'Invalid Checksum' });
        }

        const orderId = vnp_Params.vnp_TxnRef;
        const rspCode = vnp_Params.vnp_ResponseCode;
        const transactionStatus = vnp_Params.vnp_TransactionStatus;
        const vnpAmount = parseInt(vnp_Params.vnp_Amount) / 100;
        const vnpTransactionNo = vnp_Params.vnp_TransactionNo;

        // === Case 1: Payment booking (orderId bắt đầu bằng VNPAY) ===
        if (orderId.startsWith('VNPAY')) {
            const payment = await Payment.findOne({ transactionId: orderId });
            if (!payment) {
                console.log('VNPay IPN: Payment not found for', orderId);
                return res.status(200).json({ RspCode: '01', Message: 'Order not found' });
            }

            // Kiểm tra amount
            if (payment.amount !== vnpAmount) {
                console.log('VNPay IPN: Invalid amount', payment.amount, vnpAmount);
                return res.status(200).json({ RspCode: '04', Message: 'Invalid amount' });
            }

            // Kiểm tra đã xử lý chưa
            if (payment.status === 'completed') {
                return res.status(200).json({ RspCode: '02', Message: 'Order already confirmed' });
            }

            if (rspCode === '00' && transactionStatus === '00') {
                // Thanh toán thành công → confirm booking
                await processBookingPaymentSuccess(payment, vnpTransactionNo);
            } else {
                payment.status = 'failed';
                await payment.save();
            }

            return res.status(200).json({ RspCode: '00', Message: 'Confirm Success' });
        }

        // === Case 2: Wallet top-up (orderId bắt đầu bằng TOPUP) ===
        if (orderId.startsWith('TOPUP')) {
            const transaction = await Transaction.findOne({ vnpTxnRef: orderId });
            if (!transaction) {
                console.log('VNPay IPN: Transaction not found for', orderId);
                return res.status(200).json({ RspCode: '01', Message: 'Order not found' });
            }

            if (transaction.amount !== vnpAmount) {
                return res.status(200).json({ RspCode: '04', Message: 'Invalid amount' });
            }

            if (transaction.status === 'success') {
                return res.status(200).json({ RspCode: '02', Message: 'Order already confirmed' });
            }

            if (rspCode === '00' && transactionStatus === '00') {
                await processTopupSuccess(transaction);
            } else {
                transaction.status = 'failed';
                await transaction.save();
            }

            return res.status(200).json({ RspCode: '00', Message: 'Confirm Success' });
        }

        return res.status(200).json({ RspCode: '01', Message: 'Order not found' });
    } catch (error) {
        console.error('VNPay IPN error:', error);
        return res.status(200).json({ RspCode: '99', Message: 'Unknown error' });
    }
};

// ============ RETURN URL - REDIRECT BROWSER SAU THANH TOÁN ============
const vnpayReturn = async (req, res) => {
    try {
        const vnp_Params = req.query;
        console.log('vnpayReturn: Received params:', JSON.stringify(vnp_Params));

        const isValid = verifyChecksum(vnp_Params);
        const rspCode = vnp_Params.vnp_ResponseCode;
        const orderId = vnp_Params.vnp_TxnRef;
        const amount = parseInt(vnp_Params.vnp_Amount) / 100;

        console.log('vnpayReturn: isValid:', isValid, 'rspCode:', rspCode, 'orderId:', orderId, 'amount:', amount);

        let success = isValid && rspCode === '00';
        let message = success ? 'Giao dịch thành công' : 'Giao dịch không thành công';

        if (!isValid) {
            console.error('vnpayReturn: INVALID CHECKSUM!');
            message = 'Dữ liệu không hợp lệ (sai chữ ký)';
        }

        // Nếu IPN chưa xử lý (trường hợp IPN chậm), xử lý tại đây
        if (success) {
            try {
                if (orderId.startsWith('VNPAY')) {
                    const payment = await Payment.findOne({ transactionId: orderId });
                    console.log('vnpayReturn: Payment found:', payment ? payment.status : 'NOT FOUND');
                    if (payment && payment.status === 'pending') {
                        await processBookingPaymentSuccess(payment, vnp_Params.vnp_TransactionNo);
                        console.log('vnpayReturn: Booking payment processed successfully');
                    }
                } else if (orderId.startsWith('TOPUP')) {
                    const transaction = await Transaction.findOne({ vnpTxnRef: orderId });
                    console.log('vnpayReturn: Transaction found:', transaction ? transaction.status : 'NOT FOUND');
                    if (transaction && transaction.status === 'pending') {
                        await processTopupSuccess(transaction);
                        console.log('vnpayReturn: Top-up processed successfully');
                    } else if (transaction) {
                        console.log('vnpayReturn: Transaction already processed, status:', transaction.status);
                    }
                }
            } catch (processError) {
                console.error('vnpayReturn: Error processing payment/topup:', processError);
                // Vẫn hiển thị trang kết quả, nhưng log lỗi
            }
        }

        // Trả HTML page kết quả (Flutter WebView sẽ detect URL)
        const html = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kết quả thanh toán</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; background: ${success ? '#f0fdf4' : '#fef2f2'}; }
        .container { text-align: center; padding: 40px 24px; }
        .icon { font-size: 80px; margin-bottom: 20px; }
        .title { font-size: 24px; font-weight: 700; color: ${success ? '#16a34a' : '#dc2626'}; margin-bottom: 8px; }
        .subtitle { font-size: 14px; color: #6b7280; margin-bottom: 24px; }
        .amount { font-size: 28px; font-weight: 800; color: #1e3a5f; margin-bottom: 32px; }
        .info { font-size: 12px; color: #9ca3af; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">${success ? '✅' : '❌'}</div>
        <div class="title">${message}</div>
        <div class="subtitle">Mã giao dịch: ${orderId}</div>
        <div class="amount">${formatCurrency(amount)}</div>
        <div class="info">Bạn có thể đóng trang này và quay lại ứng dụng</div>
    </div>
</body>
</html>`;

        res.setHeader('Content-Type', 'text/html');
        return res.status(200).send(html);
    } catch (error) {
        console.error('vnpayReturn: Fatal error:', error);
        res.setHeader('Content-Type', 'text/html');
        return res.status(200).send('<h1>Đã xảy ra lỗi</h1>');
    }
};

// ============ HELPER: Xử lý thanh toán booking thành công ============
async function processBookingPaymentSuccess(payment, vnpTransactionNo) {
    console.log('processBookingPaymentSuccess: Starting for payment', payment._id);

    try {
        const session = await mongoose.startSession();
        session.startTransaction();

        try {
            payment.status = 'completed';
            payment.paidAt = new Date();
            payment.vnpTransactionNo = vnpTransactionNo || '';
            await payment.save({ session });

            const booking = await Booking.findById(payment.booking).session(session);
            if (booking) {
                booking.status = 'confirmed';
                await booking.save({ session });

                if (booking.timeSlots && booking.timeSlots.length > 0) {
                    await TimeSlot.updateMany(
                        { _id: { $in: booking.timeSlots }, status: 'locked' },
                        { $set: { status: 'booked', lockedAt: null } },
                        { session }
                    );
                }
            }

            await session.commitTransaction();
            session.endSession();
            console.log('processBookingPaymentSuccess: Session committed successfully');
        } catch (sessionError) {
            await session.abortTransaction();
            session.endSession();
            console.error('processBookingPaymentSuccess: Session failed, falling back:', sessionError.message);

            // Fallback: cập nhật không dùng session
            payment.status = 'completed';
            payment.paidAt = new Date();
            payment.vnpTransactionNo = vnpTransactionNo || '';
            await payment.save();

            const booking = await Booking.findById(payment.booking);
            if (booking) {
                booking.status = 'confirmed';
                await booking.save();

                if (booking.timeSlots && booking.timeSlots.length > 0) {
                    await TimeSlot.updateMany(
                        { _id: { $in: booking.timeSlots }, status: 'locked' },
                        { $set: { status: 'booked', lockedAt: null } }
                    );
                }
            }
            console.log('processBookingPaymentSuccess: Fallback updates completed');
        }

        // Tạo thông báo (ngoài transaction)
        try {
            await Notification.create({
                user: payment.user,
                title: 'Thanh toán VNPay thành công',
                content: `Thanh toán ${formatCurrency(payment.amount)} qua VNPay thành công. Khung giờ đã được xác nhận.`,
                type: 'payment',
                data: { paymentId: payment._id, bookingId: payment.booking }
            });
        } catch (notifErr) {
            console.error('processBookingPaymentSuccess: Notification error:', notifErr.message);
        }
    } catch (error) {
        console.error('processBookingPaymentSuccess: Fatal error:', error);
        throw error;
    }
}

// ============ HELPER: Xử lý nạp tiền ví thành công ============
async function processTopupSuccess(transaction) {
    console.log('processTopupSuccess: Starting for transaction', transaction._id, 'amount:', transaction.amount);

    try {
        // Thử dùng session (transaction) trước
        const session = await mongoose.startSession();
        session.startTransaction();

        try {
            transaction.status = 'success';
            await transaction.save({ session });

            const wallet = await Wallet.findById(transaction.wallet).session(session);
            if (wallet) {
                wallet.balance += transaction.amount;
                await wallet.save({ session });
                console.log('processTopupSuccess: Wallet updated (session), new balance:', wallet.balance);
            } else {
                console.error('processTopupSuccess: Wallet not found for id:', transaction.wallet);
            }

            await session.commitTransaction();
            session.endSession();
            console.log('processTopupSuccess: Session committed successfully');
        } catch (sessionError) {
            await session.abortTransaction();
            session.endSession();
            console.error('processTopupSuccess: Session failed, falling back to non-session:', sessionError.message);

            // Fallback: cập nhật không dùng session
            transaction.status = 'success';
            await transaction.save();

            const wallet = await Wallet.findById(transaction.wallet);
            if (wallet) {
                wallet.balance += transaction.amount;
                await wallet.save();
                console.log('processTopupSuccess: Wallet updated (no session), new balance:', wallet.balance);
            } else {
                console.error('processTopupSuccess: Wallet not found for id:', transaction.wallet);
            }
        }

        // Tạo thông báo (ngoài transaction)
        try {
            await Notification.create({
                user: transaction.user,
                title: 'Nạp tiền thành công',
                content: `Nạp ${formatCurrency(transaction.amount)} vào ví qua VNPay thành công.`,
                type: 'payment',
                data: { transactionId: transaction._id }
            });
            console.log('processTopupSuccess: Notification created');
        } catch (notifErr) {
            console.error('processTopupSuccess: Notification error:', notifErr.message);
        }
    } catch (error) {
        console.error('processTopupSuccess: Fatal error:', error);
        throw error;
    }
}

// ============ PROCESS RETURN - MOBILE APP GỌI TRỰC TIẾP ============
const processReturn = async (req, res) => {
    try {
        const vnp_Params = req.body;
        console.log('processReturn: params:', JSON.stringify(vnp_Params));

        if (!vnp_Params || !vnp_Params.vnp_TxnRef) {
            return res.status(400).json({ success: false, message: 'Thiếu tham số VNPay' });
        }

        const isValid = verifyChecksum(vnp_Params);
        const rspCode = vnp_Params.vnp_ResponseCode;
        const orderId = vnp_Params.vnp_TxnRef;
        const vnpAmount = parseInt(vnp_Params.vnp_Amount) / 100;

        console.log('processReturn: isValid:', isValid, 'rspCode:', rspCode, 'orderId:', orderId);

        if (!isValid) {
            console.error('processReturn: INVALID CHECKSUM');
            return res.status(400).json({ success: false, message: 'Chữ ký không hợp lệ' });
        }

        if (rspCode !== '00') {
            return res.status(200).json({ success: false, message: 'Giao dịch không thành công' });
        }

        // Xử lý booking payment
        if (orderId.startsWith('VNPAY')) {
            const payment = await Payment.findOne({ transactionId: orderId });
            if (!payment) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy giao dịch' });
            }
            if (payment.status === 'completed') {
                return res.status(200).json({ success: true, message: 'Đã xử lý trước đó' });
            }
            await processBookingPaymentSuccess(payment, vnp_Params.vnp_TransactionNo);
            console.log('processReturn: Booking payment done');
            return res.status(200).json({ success: true, message: 'Thanh toán thành công' });
        }

        // Xử lý top-up
        if (orderId.startsWith('TOPUP')) {
            const transaction = await Transaction.findOne({ vnpTxnRef: orderId });
            if (!transaction) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy giao dịch' });
            }
            if (transaction.status === 'success') {
                return res.status(200).json({ success: true, message: 'Đã xử lý trước đó' });
            }
            await processTopupSuccess(transaction);
            console.log('processReturn: Top-up done');
            return res.status(200).json({ success: true, message: 'Nạp tiền thành công' });
        }

        return res.status(404).json({ success: false, message: 'Mã giao dịch không hợp lệ' });
    } catch (error) {
        console.error('processReturn error:', error);
        return res.status(500).json({ success: false, message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    createBookingPaymentUrl,
    createTopupUrl,
    vnpayIPN,
    vnpayReturn,
    processReturn,
};

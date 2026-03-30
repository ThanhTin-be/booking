const mongoose = require('mongoose');

const PaymentSchema = new mongoose.Schema({
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true },
    method: {
        type: String,
        enum: ['cash', 'bank', 'momo', 'wallet', 'vnpay'],
        default: 'cash'
    },
    status: {
        type: String,
        enum: ['pending', 'completed', 'failed', 'refunded'],
        default: 'pending'
    },
    transactionId: { type: String, default: null }, // Mã giao dịch bên ngoài
    qrCodeData: { type: String, default: null },     // Dữ liệu QR
    vnpTransactionNo: { type: String, default: null }, // Mã giao dịch VNPay trả về
    paidAt: { type: Date, default: null }
}, { timestamps: true });

module.exports = mongoose.model('Payment', PaymentSchema);


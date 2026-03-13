const mongoose = require('mongoose');

const TransactionSchema = new mongoose.Schema({
    wallet: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet', required: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: {
        type: String,
        enum: ['top_up', 'payment', 'refund'],
        required: true
    },
    amount: { type: Number, required: true }, // Số dương = cộng, số âm = trừ
    description: { type: String, default: '' },
    relatedBooking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
    status: { type: String, enum: ['success', 'failed'], default: 'success' }
}, { timestamps: true });

TransactionSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('Transaction', TransactionSchema);


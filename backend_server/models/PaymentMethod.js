const mongoose = require('mongoose');

const PaymentMethodSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, enum: ['visa', 'momo', 'bank', 'vnpay'], required: true },
    name: { type: String, required: true }, // VD: "Visa •••• 1234", "Ví MoMo"
    accountNumber: { type: String, default: '' }, // Số tài khoản (masked)
    bankName: { type: String, default: '' },
    isDefault: { type: Boolean, default: false }
}, { timestamps: true });

PaymentMethodSchema.index({ user: 1 });

module.exports = mongoose.model('PaymentMethod', PaymentMethodSchema);


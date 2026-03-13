const mongoose = require('mongoose');

const DiscountSchema = new mongoose.Schema({
    code: { type: String, required: true, unique: true, uppercase: true },
    description: { type: String, default: '' },
    discountType: { type: String, enum: ['percent', 'fixed'], default: 'fixed' }, // Giảm % hoặc số tiền cố định
    discountValue: { type: Number, required: true }, // VD: 20 (20% hoặc 20000đ)
    maxDiscountAmount: { type: Number, default: null }, // Giới hạn tối đa giảm (cho loại percent)
    minOrderValue: { type: Number, default: 0 }, // Giá trị đơn tối thiểu
    validFrom: { type: Date, default: Date.now },
    validTo: { type: Date, required: true },
    usageLimit: { type: Number, default: 100 }, // Tổng số lần dùng tối đa
    usedCount: { type: Number, default: 0 },    // Số lần đã dùng
    status: { type: String, enum: ['active', 'expired', 'disabled'], default: 'active' },
    applicableUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }] // Rỗng = áp dụng cho tất cả
}, { timestamps: true });

module.exports = mongoose.model('Discount', DiscountSchema);


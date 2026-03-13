const mongoose = require('mongoose');

const SubCourtSchema = new mongoose.Schema({
    court: { type: mongoose.Schema.Types.ObjectId, ref: 'Court', required: true },
    name: { type: String, required: true }, // VD: "Sân 1", "Sân 2"
    type: { type: String, enum: ['standard', 'vip'], default: 'standard' },
    pricePerSlot: { type: Number, default: 0 }, // Giá riêng, nếu 0 thì lấy giá sân cha
    status: { type: String, enum: ['active', 'maintenance'], default: 'active' }
}, { timestamps: true });

module.exports = mongoose.model('SubCourt', SubCourtSchema);


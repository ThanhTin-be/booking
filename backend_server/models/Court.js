const mongoose = require('mongoose');

const CourtSchema = new mongoose.Schema({
    name: { type: String, required: true },
    description: String,
    address: String,
    category: { type: String, required: true }, // Cầu lông, Bóng đá, Tennis, Pickleball
    pricePerHour: { type: Number, required: true },
    pricePerSlot: { type: Number, default: 50000 }, // Giá mỗi slot 30 phút
    images: [{ type: String }],
    logoUrl: { type: String, default: '' },
    openTime: { type: String, default: '06:00' }, // Giờ mở cửa
    closeTime: { type: String, default: '22:00' }, // Giờ đóng cửa
    tags: [{ type: String }], // VD: ["Đơn ngày", "Sự kiện", "VIP"]
    // GeoJSON: Tọa độ để làm bản đồ
    location: {
        type: { type: String, default: 'Point' },
        coordinates: { type: [Number], index: '2dsphere' } // [kinh độ, vĩ độ]
    },
    ratingAvg: { type: Number, default: 0 },
    totalReviews: { type: Number, default: 0 },
    amenities: [String], // ["wifi", "parking", "water"]
    status: { type: String, enum: ['active', 'maintenance'], default: 'active' }
}, { timestamps: true });

CourtSchema.index({ name: 'text', address: 'text' }); // Text search index

module.exports = mongoose.model('Court', CourtSchema);
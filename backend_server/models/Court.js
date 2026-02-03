const mongoose = require('mongoose');

const CourtSchema = new mongoose.Schema({name: { type: String, required: true },
    description: String,
    address: String,
    category: { type: String, required: true }, // Cầu lông, Bóng đá...
    pricePerHour: { type: Number, required: true },
    images: [{ type: String }],
    // GeoJSON: Tọa độ để làm bản đồ
    location: {
        type: { type: String, default: 'Point' },
        coordinates: { type: [Number], index: '2dsphere' } // [kinh độ, vĩ độ]
    },
    ratingAvg: { type: Number, default: 0 },
    amenities: [String], // ["wifi", "parking", "water"]
    status: { type: String, enum: ['active', 'maintenance'], default: 'active' }
}, { timestamps: true });

module.exports = mongoose.model('Court', CourtSchema);
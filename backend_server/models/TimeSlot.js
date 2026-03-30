const mongoose = require('mongoose');

const TimeSlotSchema = new mongoose.Schema({
    court: { type: mongoose.Schema.Types.ObjectId, ref: 'Court', required: true },
    subCourt: { type: mongoose.Schema.Types.ObjectId, ref: 'SubCourt', required: true },
    date: { type: String, required: true }, // Format: "YYYY-MM-DD"
    startTime: { type: String, required: true }, // VD: "15:30"
    endTime: { type: String, required: true },   // VD: "16:00"
    status: {
        type: String,
        enum: ['available', 'booked', 'locked'],
        default: 'available'
    },
    price: { type: Number, default: 50000 }, // Giá mỗi slot (30 phút)
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
    lockedAt: { type: Date, default: null } // Thời gian bị lock, dùng để auto-release
}, { timestamps: true });

// Index tổ hợp để query nhanh
TimeSlotSchema.index({ court: 1, subCourt: 1, date: 1 });
TimeSlotSchema.index({ subCourt: 1, date: 1, status: 1 });
TimeSlotSchema.index({ subCourt: 1, date: 1, startTime: 1 }, { unique: true }); // Ngăn duplicate slot

module.exports = mongoose.model('TimeSlot', TimeSlotSchema);


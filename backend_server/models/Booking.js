const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    court: { type: mongoose.Schema.Types.ObjectId, ref: 'Court', required: true },
    subCourt: { type: mongoose.Schema.Types.ObjectId, ref: 'SubCourt', default: null },
    date: { type: String, required: true }, // Format: "YYYY-MM-DD"
    timeSlots: [{ type: mongoose.Schema.Types.ObjectId, ref: 'TimeSlot' }], // Danh sách slot đã chọn
    startTime: { type: String, required: true }, // VD: "14:00"
    endTime: { type: String, required: true },   // VD: "16:00"
    totalPrice: { type: Number, required: true },
    discountAmount: { type: Number, default: 0 },
    finalPrice: { type: Number, required: true },
    discount: { type: mongoose.Schema.Types.ObjectId, ref: 'Discount', default: null },
    status: {
        type: String, 
        enum: ['pending', 'confirmed', 'cancelled', 'completed'], 
        default: 'pending' 
    },
    paymentMethod: { type: String, default: 'cash' }, // cash, momo, bank, wallet
    contactName: { type: String, default: '' },
    contactPhone: { type: String, default: '' },
    bookingCode: { type: String, unique: true } // Mã vé: BK1001, BK1002...
}, { timestamps: true });

BookingSchema.index({ user: 1, status: 1 });
BookingSchema.index({ court: 1, date: 1 });

module.exports = mongoose.model('Booking', BookingSchema);
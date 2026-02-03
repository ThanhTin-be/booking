const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    court: { type: mongoose.Schema.Types.ObjectId, ref: 'Court', required: true },
    date: { type: Date, required: true }, // Ngày đặt
    startTime: { type: String, required: true }, // VD: "14:00"
    endTime: { type: String, required: true },   // VD: "16:00"
    totalPrice: { type: Number, required: true },
    status: { 
        type: String, 
        enum: ['pending', 'confirmed', 'cancelled', 'completed'], 
        default: 'pending' 
    },
    paymentMethod: { type: String, default: 'cash' } // cash, momo, vnpay
}, { timestamps: true });

module.exports = mongoose.model('Booking', BookingSchema);
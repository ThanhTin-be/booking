const mongoose = require('mongoose');

const WalletSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    balance: { type: Number, default: 0 },
    points: { type: Number, default: 0 }, // Điểm thưởng
    tier: { type: String, enum: ['member', 'silver', 'gold', 'platinum'], default: 'member' }
}, { timestamps: true });

module.exports = mongoose.model('Wallet', WalletSchema);


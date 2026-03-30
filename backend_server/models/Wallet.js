const mongoose = require('mongoose');
const { getTierFromPoints } = require('../utils/tier');

const WalletSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    balance: { type: Number, default: 0 },
    points: { type: Number, default: 0 }, // Điểm thưởng
    tier: { type: String, enum: ['member', 'silver', 'gold', 'platinum'], default: 'member' }
}, { timestamps: true });

WalletSchema.pre('save', function () {
    if (this.isModified('points')) {
        this.tier = getTierFromPoints(this.points);
    }
});

module.exports = mongoose.model('Wallet', WalletSchema);


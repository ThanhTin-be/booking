const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');

// ============ LẤY SỐ DƯ VÍ ============
const getBalance = async (req, res) => {
    try {
        const userId = req.user.id;

        // Tự tạo ví nếu chưa có
        let wallet = await Wallet.findOne({ user: userId });
        if (!wallet) {
            wallet = await Wallet.create({ user: userId, balance: 0, points: 0 });
        }

        return res.status(200).json({
            message: 'Lấy số dư ví thành công',
            wallet: {
                id: wallet._id,
                balance: wallet.balance,
                points: wallet.points,
                tier: wallet.tier
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ NẠP TIỀN VÀO VÍ ============
const topUp = async (req, res) => {
    try {
        const userId = req.user.id;
        const { amount } = req.body;

        if (!amount || amount <= 0) {
            return res.status(400).json({ message: 'Số tiền nạp phải lớn hơn 0' });
        }

        if (amount < 10000) {
            return res.status(400).json({ message: 'Số tiền nạp tối thiểu 10.000đ' });
        }

        // Tìm hoặc tạo ví
        let wallet = await Wallet.findOne({ user: userId });
        if (!wallet) {
            wallet = await Wallet.create({ user: userId, balance: 0, points: 0 });
        }

        // Cộng tiền
        wallet.balance += amount;

        // Cộng điểm thưởng (1 điểm / 10.000đ nạp)
        const earnedPoints = Math.floor(amount / 10000);
        wallet.points += earnedPoints;

        // Cập nhật tier
        if (wallet.points >= 1000) wallet.tier = 'platinum';
        else if (wallet.points >= 500) wallet.tier = 'gold';
        else if (wallet.points >= 100) wallet.tier = 'silver';
        else wallet.tier = 'member';

        await wallet.save();

        // Tạo giao dịch
        await Transaction.create({
            wallet: wallet._id,
            user: userId,
            type: 'top_up',
            amount: amount,
            description: `Nạp tiền vào ví +${formatCurrency(amount)}`,
            status: 'success'
        });

        return res.status(200).json({
            message: 'Nạp tiền thành công',
            wallet: {
                balance: wallet.balance,
                points: wallet.points,
                tier: wallet.tier,
                earnedPoints
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ LỊCH SỬ GIAO DỊCH ============
const getTransactionHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        const { type, page = 1, limit = 20 } = req.query;

        const filter = { user: userId };
        if (type) filter.type = type; // top_up, payment, refund

        const transactions = await Transaction.find(filter)
            .populate('relatedBooking', 'bookingCode')
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        const total = await Transaction.countDocuments(filter);

        return res.status(200).json({
            message: 'Lấy lịch sử giao dịch thành công',
            transactions,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// Helper format tiền
function formatCurrency(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + 'đ';
}

module.exports = {
    getBalance,
    topUp,
    getTransactionHistory
};


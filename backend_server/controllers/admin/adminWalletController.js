const mongoose = require('mongoose');
const Wallet = require('../../models/Wallet');
const User = require('../../models/User');
const Transaction = require('../../models/Transaction');
const { parsePagination, parseSort } = require('../../utils/pagination');
const { buildRegexQuery } = require('../../utils/query');

// ============ DANH SÁCH VÍ (có kèm thông tin user) ============
const listWallets = async (req, res) => {
    try {
        const { q, tier } = req.query;
        const { page, limit, skip } = parsePagination(req.query);
        const sort = parseSort(req.query.sort, { createdAt: -1 });

        // Tìm user khớp query trước
        let userFilter = {};
        const rx = buildRegexQuery(q);
        if (rx) {
            userFilter.$or = [
                { fullName: rx },
                { email: rx },
                { phone: rx }
            ];
        }

        let matchedUserIds = null;
        if (q) {
            const matchedUsers = await User.find(userFilter).select('_id');
            matchedUserIds = matchedUsers.map((u) => u._id);
        }

        // Build wallet filter
        const walletFilter = {};
        if (matchedUserIds) {
            walletFilter.user = { $in: matchedUserIds };
        }
        if (tier) {
            walletFilter.tier = tier;
        }

        const [wallets, total] = await Promise.all([
            Wallet.find(walletFilter)
                .populate('user', 'fullName email phone avatar status')
                .skip(skip)
                .limit(limit)
                .sort(sort),
            Wallet.countDocuments(walletFilter)
        ]);

        // Tính tổng hợp
        const allWallets = await Wallet.find(walletFilter);
        const totalBalance = allWallets.reduce((sum, w) => sum + (w.balance || 0), 0);
        const totalPoints = allWallets.reduce((sum, w) => sum + (w.points || 0), 0);
        const tierCounts = { member: 0, silver: 0, gold: 0, platinum: 0 };
        allWallets.forEach((w) => { tierCounts[w.tier] = (tierCounts[w.tier] || 0) + 1; });

        return res.status(200).json({
            message: 'Admin list wallets',
            wallets,
            summary: {
                totalWallets: total,
                totalBalance,
                totalPoints,
                tierCounts
            },
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ CẬP NHẬT SỐ DƯ / ĐIỂM ============
const updateWallet = async (req, res) => {
    try {
        const { id } = req.params;
        const { balance, points } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Wallet id không hợp lệ' });
        }

        const wallet = await Wallet.findById(id);
        if (!wallet) {
            return res.status(404).json({ message: 'Không tìm thấy ví' });
        }

        if (balance !== undefined) {
            if (typeof balance !== 'number' || balance < 0) {
                return res.status(400).json({ message: 'Số dư phải là số không âm' });
            }
            wallet.balance = balance;
        }

        if (points !== undefined) {
            if (typeof points !== 'number' || points < 0) {
                return res.status(400).json({ message: 'Điểm phải là số không âm' });
            }
            wallet.points = points;
            // tier sẽ tự động tính lại qua pre('save') hook
        }

        await wallet.save();

        const updated = await Wallet.findById(id).populate('user', 'fullName email phone avatar status');

        return res.status(200).json({
            message: 'Cập nhật ví thành công',
            wallet: updated
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    listWallets,
    updateWallet
};

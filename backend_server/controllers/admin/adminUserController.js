const mongoose = require('mongoose');
const User = require('../../models/User');
const Wallet = require('../../models/Wallet');
const Booking = require('../../models/Booking');
const Transaction = require('../../models/Transaction');
const { parsePagination, parseSort } = require('../../utils/pagination');
const { buildRegexQuery } = require('../../utils/query');

const SAFE_USER_SELECT = '-password -refreshTokens -verificationCode -verificationCodeExpires -resetPasswordCode -resetPasswordCodeExpires';

const listUsers = async (req, res) => {
    try {
        const { q, status, role } = req.query;
        const { page, limit, skip } = parsePagination(req.query);
        const sort = parseSort(req.query.sort, { createdAt: -1 });

        const filter = {};
        if (status) filter.status = status;
        if (role) filter.role = role;

        const rx = buildRegexQuery(q);
        if (rx) {
            filter.$or = [
                { fullName: rx },
                { email: rx },
                { phone: rx }
            ];
        }

        const [users, total] = await Promise.all([
            User.find(filter).select(SAFE_USER_SELECT).skip(skip).limit(limit).sort(sort),
            User.countDocuments(filter)
        ]);

        const userIds = users.map((u) => u._id);
        const wallets = await Wallet.find({ user: { $in: userIds } }).select('user balance points tier');
        const walletMap = wallets.reduce((acc, w) => {
            acc[w.user.toString()] = {
                balance: w.balance,
                points: w.points,
                tier: w.tier
            };
            return acc;
        }, {});

        const usersWithWallet = users.map((u) => ({
            ...u.toObject(),
            wallet: walletMap[u._id.toString()] || {
                balance: 0,
                points: 0,
                tier: 'member'
            }
        }));

        return res.status(200).json({
            message: 'Admin list users',
            users: usersWithWallet,
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

const getUserDetail = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'User id không hợp lệ' });
        }

        const user = await User.findById(id).select(SAFE_USER_SELECT);
        if (!user) return res.status(404).json({ message: 'Không tìm thấy user' });

        const [wallet, bookingAgg, transactionsTotal] = await Promise.all([
            Wallet.findOne({ user: id }).select('balance points tier'),
            Booking.aggregate([
                { $match: { user: user._id } },
                {
                    $group: {
                        _id: null,
                        bookingsTotal: { $sum: 1 },
                        totalSpent: { $sum: '$finalPrice' }
                    }
                }
            ]),
            Transaction.countDocuments({ user: user._id })
        ]);

        const statsAgg = bookingAgg?.[0] || { bookingsTotal: 0, totalSpent: 0 };

        return res.status(200).json({
            message: 'Admin user detail',
            user,
            wallet: wallet
                ? {
                      balance: wallet.balance,
                      points: wallet.points,
                      tier: wallet.tier
                  }
                : {
                      balance: 0,
                      points: 0,
                      tier: 'member'
                  },
            stats: {
                bookingsTotal: statsAgg.bookingsTotal,
                totalSpent: statsAgg.totalSpent,
                transactionsTotal
            }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateUserStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'User id không hợp lệ' });
        }
        if (!['active', 'locked'].includes(status)) {
            return res.status(400).json({ message: "status phải là 'active' hoặc 'locked'" });
        }
        if (req.user?.id === id && status === 'locked') {
            return res.status(400).json({ message: 'Không thể tự khóa tài khoản admin đang đăng nhập' });
        }

        const user = await User.findByIdAndUpdate(
            id,
            { $set: { status } },
            { new: true }
        ).select(SAFE_USER_SELECT);

        if (!user) return res.status(404).json({ message: 'Không tìm thấy user' });
        return res.status(200).json({ message: 'Cập nhật trạng thái user thành công', user });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateUserRole = async (req, res) => {
    try {
        const { id } = req.params;
        const { role } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'User id không hợp lệ' });
        }
        if (!['customer', 'admin'].includes(role)) {
            return res.status(400).json({ message: "role phải là 'customer' hoặc 'admin'" });
        }
        if (req.user?.id === id && role !== 'admin') {
            return res.status(400).json({ message: 'Không thể tự hạ quyền chính mình' });
        }

        const user = await User.findByIdAndUpdate(
            id,
            { $set: { role } },
            { new: true }
        ).select(SAFE_USER_SELECT);

        if (!user) return res.status(404).json({ message: 'Không tìm thấy user' });
        return res.status(200).json({ message: 'Cập nhật role user thành công', user });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    listUsers,
    getUserDetail,
    updateUserStatus,
    updateUserRole
};


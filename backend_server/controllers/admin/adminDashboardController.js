const Booking = require('../../models/Booking');
const Payment = require('../../models/Payment');
const User = require('../../models/User');
const Court = require('../../models/Court');
const Wallet = require('../../models/Wallet');

function parseDateRange(from, to) {
    // Accept YYYY-MM-DD; fall back to last 30 days
    const today = new Date();
    const defaultTo = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate(), 23, 59, 59, 999));
    const defaultFrom = new Date(defaultTo);
    defaultFrom.setUTCDate(defaultFrom.getUTCDate() - 29);
    defaultFrom.setUTCHours(0, 0, 0, 0);

    const fromDate = from ? new Date(`${from}T00:00:00.000Z`) : defaultFrom;
    const toDate = to ? new Date(`${to}T23:59:59.999Z`) : defaultTo;

    if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) {
        return { error: 'from/to không hợp lệ (format: YYYY-MM-DD)' };
    }
    if (fromDate > toDate) {
        return { error: 'from phải nhỏ hơn hoặc bằng to' };
    }
    return { fromDate, toDate };
}

const getOverview = async (req, res) => {
    try {
        const { from, to } = req.query;
        const range = parseDateRange(from, to);
        if (range.error) return res.status(400).json({ message: range.error });
        const { fromDate, toDate } = range;

        const bookingMatch = { createdAt: { $gte: fromDate, $lte: toDate } };
        const paymentMatch = { createdAt: { $gte: fromDate, $lte: toDate } };
        const userMatch = { createdAt: { $gte: fromDate, $lte: toDate } };

        const [
            bookingsTotal,
            bookingsByStatus,
            revenueAgg,
            paymentsByStatus,
            newUsersTotal,
            topCourtsAgg,
            courtsTotal,
            usersByTier,
            topUsersByPoints
        ] = await Promise.all([
            Booking.countDocuments(bookingMatch),
            Booking.aggregate([
                { $match: bookingMatch },
                { $group: { _id: '$status', count: { $sum: 1 }, totalFinalPrice: { $sum: '$finalPrice' } } },
                { $sort: { count: -1 } }
            ]),
            Payment.aggregate([
                { $match: { ...paymentMatch, status: 'completed' } },
                { $group: { _id: null, totalRevenue: { $sum: '$amount' }, count: { $sum: 1 } } }
            ]),
            Payment.aggregate([
                { $match: paymentMatch },
                { $group: { _id: '$status', count: { $sum: 1 }, totalAmount: { $sum: '$amount' } } },
                { $sort: { count: -1 } }
            ]),
            User.countDocuments(userMatch),
            Booking.aggregate([
                { $match: bookingMatch },
                { $group: { _id: '$court', bookings: { $sum: 1 }, revenue: { $sum: '$finalPrice' } } },
                { $sort: { revenue: -1 } },
                { $limit: 5 },
                {
                    $lookup: {
                        from: Court.collection.name,
                        localField: '_id',
                        foreignField: '_id',
                        as: 'court'
                    }
                },
                { $unwind: { path: '$court', preserveNullAndEmptyArrays: true } },
                {
                    $project: {
                        _id: 0,
                        courtId: '$_id',
                        courtName: '$court.name',
                        category: '$court.category',
                        bookings: 1,
                        revenue: 1
                    }
                }
            ]),
            Court.countDocuments({}),
            Wallet.aggregate([
                {
                    $group: {
                        _id: '$tier',
                        users: { $sum: 1 }
                    }
                },
                { $sort: { users: -1 } }
            ]),
            Wallet.aggregate([
                { $sort: { points: -1 } },
                { $limit: 5 },
                {
                    $lookup: {
                        from: User.collection.name,
                        localField: 'user',
                        foreignField: '_id',
                        as: 'user'
                    }
                },
                { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
                {
                    $project: {
                        _id: 0,
                        userId: '$user._id',
                        fullName: '$user.fullName',
                        email: '$user.email',
                        phone: '$user.phone',
                        role: '$user.role',
                        status: '$user.status',
                        balance: '$balance',
                        points: '$points',
                        tier: '$tier'
                    }
                }
            ])
        ]);

        const revenue = revenueAgg?.[0]?.totalRevenue || 0;
        const revenuePaymentsCount = revenueAgg?.[0]?.count || 0;

        return res.status(200).json({
            message: 'Admin dashboard overview',
            range: {
                from: fromDate.toISOString(),
                to: toDate.toISOString()
            },
            metrics: {
                bookingsTotal,
                revenue,
                revenuePaymentsCount,
                newUsersTotal,
                courtsTotal
            },
            breakdown: {
                bookingsByStatus,
                paymentsByStatus,
                usersByTier
            },
            topCourts: topCourtsAgg,
            topUsersByPoints
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = { getOverview };


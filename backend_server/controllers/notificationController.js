const Notification = require('../models/Notification');

// ============ LẤY DANH SÁCH THÔNG BÁO ============
const getNotifications = async (req, res) => {
    try {
        const userId = req.user.id;
        const { page = 1, limit = 20 } = req.query;

        const notifications = await Notification.find({ user: userId })
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        const total = await Notification.countDocuments({ user: userId });
        const unreadCount = await Notification.countDocuments({ user: userId, isRead: false });

        return res.status(200).json({
            message: 'Lấy danh sách thông báo thành công',
            notifications,
            unreadCount,
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

// ============ ĐÁNH DẤU ĐÃ ĐỌC 1 THÔNG BÁO ============
const markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        const notification = await Notification.findOneAndUpdate(
            { _id: id, user: userId },
            { isRead: true },
            { new: true }
        );

        if (!notification) {
            return res.status(404).json({ message: 'Không tìm thấy thông báo' });
        }

        return res.status(200).json({
            message: 'Đã đánh dấu đã đọc',
            notification
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ ĐÁNH DẤU ĐÃ ĐỌC TẤT CẢ ============
const markAllAsRead = async (req, res) => {
    try {
        const userId = req.user.id;

        const result = await Notification.updateMany(
            { user: userId, isRead: false },
            { isRead: true }
        );

        return res.status(200).json({
            message: 'Đã đánh dấu đọc tất cả thông báo',
            modifiedCount: result.modifiedCount
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    getNotifications,
    markAsRead,
    markAllAsRead
};


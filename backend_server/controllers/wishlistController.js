const Wishlist = require('../models/Wishlist');
const Court = require('../models/Court');

// ============ LẤY DANH SÁCH SÂN YÊU THÍCH ============
const getWishlist = async (req, res) => {
    try {
        const userId = req.user.id;

        let wishlist = await Wishlist.findOne({ user: userId })
            .populate('courts', 'name address images logoUrl openTime closeTime tags ratingAvg category location pricePerHour');

        if (!wishlist) {
            wishlist = await Wishlist.create({ user: userId, courts: [] });
        }

        return res.status(200).json({
            message: 'Lấy danh sách yêu thích thành công',
            courts: wishlist.courts,
            total: wishlist.courts.length
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ THÊM SÂN VÀO YÊU THÍCH ============
const addCourt = async (req, res) => {
    try {
        const userId = req.user.id;
        const { courtId } = req.params;

        // Kiểm tra sân tồn tại
        const court = await Court.findById(courtId);
        if (!court) {
            return res.status(404).json({ message: 'Không tìm thấy sân' });
        }

        // Tìm hoặc tạo wishlist
        let wishlist = await Wishlist.findOne({ user: userId });
        if (!wishlist) {
            wishlist = await Wishlist.create({ user: userId, courts: [] });
        }

        // Kiểm tra đã có trong list chưa
        if (wishlist.courts.includes(courtId)) {
            return res.status(400).json({ message: 'Sân đã có trong danh sách yêu thích' });
        }

        // Thêm vào (dùng $addToSet để tránh trùng)
        wishlist = await Wishlist.findOneAndUpdate(
            { user: userId },
            { $addToSet: { courts: courtId } },
            { new: true }
        ).populate('courts', 'name address images');

        return res.status(200).json({
            message: `Đã thêm "${court.name}" vào danh sách yêu thích`,
            courts: wishlist.courts,
            total: wishlist.courts.length
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ BỎ SÂN KHỎI YÊU THÍCH ============
const removeCourt = async (req, res) => {
    try {
        const userId = req.user.id;
        const { courtId } = req.params;

        const wishlist = await Wishlist.findOneAndUpdate(
            { user: userId },
            { $pull: { courts: courtId } },
            { new: true }
        ).populate('courts', 'name address images');

        if (!wishlist) {
            return res.status(404).json({ message: 'Không tìm thấy danh sách yêu thích' });
        }

        return res.status(200).json({
            message: 'Đã bỏ sân khỏi danh sách yêu thích',
            courts: wishlist.courts,
            total: wishlist.courts.length
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    getWishlist,
    addCourt,
    removeCourt
};


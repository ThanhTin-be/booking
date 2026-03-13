const Discount = require('../models/Discount');

// ============ LẤY DANH SÁCH VOUCHER KHẢ DỤNG ============
const getMyVouchers = async (req, res) => {
    try {
        const userId = req.user.id;

        // Lấy các discount đang active, còn hạn, còn lượt dùng
        // và áp dụng cho tất cả HOẶC cho user cụ thể
        const vouchers = await Discount.find({
            status: 'active',
            validTo: { $gte: new Date() },
            validFrom: { $lte: new Date() },
            $expr: { $lt: ['$usedCount', '$usageLimit'] },
            $or: [
                { applicableUsers: { $size: 0 } }, // Áp dụng cho tất cả
                { applicableUsers: userId }          // Hoặc cho user cụ thể
            ]
        }).sort({ validTo: 1 }); // Sắp xếp theo ngày hết hạn gần nhất

        return res.status(200).json({
            message: 'Lấy danh sách voucher thành công',
            vouchers,
            total: vouchers.length
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ ÁP DỤNG MÃ GIẢM GIÁ ============
const applyDiscount = async (req, res) => {
    try {
        const userId = req.user.id;
        const { code, orderTotal } = req.body;

        if (!code) {
            return res.status(400).json({ message: 'Vui lòng nhập mã giảm giá' });
        }

        if (!orderTotal || orderTotal <= 0) {
            return res.status(400).json({ message: 'Giá trị đơn hàng không hợp lệ' });
        }

        // Tìm mã giảm giá
        const discount = await Discount.findOne({
            code: code.toUpperCase(),
            status: 'active'
        });

        if (!discount) {
            return res.status(404).json({ message: 'Mã giảm giá không tồn tại hoặc đã bị vô hiệu' });
        }

        // Kiểm tra hạn sử dụng
        const now = new Date();
        if (now < discount.validFrom) {
            return res.status(400).json({ message: 'Mã giảm giá chưa đến thời gian sử dụng' });
        }
        if (now > discount.validTo) {
            return res.status(400).json({ message: 'Mã giảm giá đã hết hạn' });
        }

        // Kiểm tra số lần sử dụng
        if (discount.usedCount >= discount.usageLimit) {
            return res.status(400).json({ message: 'Mã giảm giá đã hết lượt sử dụng' });
        }

        // Kiểm tra giá trị đơn tối thiểu
        if (orderTotal < discount.minOrderValue) {
            return res.status(400).json({
                message: `Đơn hàng tối thiểu ${formatCurrency(discount.minOrderValue)} để áp dụng mã này`
            });
        }

        // Kiểm tra user có được áp dụng không
        if (discount.applicableUsers.length > 0 && !discount.applicableUsers.includes(userId)) {
            return res.status(400).json({ message: 'Mã giảm giá không áp dụng cho tài khoản của bạn' });
        }

        // Tính số tiền giảm
        let discountAmount = 0;
        if (discount.discountType === 'percent') {
            discountAmount = Math.floor(orderTotal * discount.discountValue / 100);
            if (discount.maxDiscountAmount) {
                discountAmount = Math.min(discountAmount, discount.maxDiscountAmount);
            }
        } else {
            discountAmount = discount.discountValue;
        }

        // Đảm bảo giảm giá không vượt quá tổng đơn
        discountAmount = Math.min(discountAmount, orderTotal);

        const finalPrice = orderTotal - discountAmount;

        return res.status(200).json({
            message: 'Áp dụng mã giảm giá thành công',
            discount: {
                id: discount._id,
                code: discount.code,
                description: discount.description,
                discountType: discount.discountType,
                discountValue: discount.discountValue,
                discountAmount,
                finalPrice
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
    getMyVouchers,
    applyDiscount
};


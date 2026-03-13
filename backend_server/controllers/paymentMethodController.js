const PaymentMethod = require('../models/PaymentMethod');

// ============ LẤY DANH SÁCH PHƯƠNG THỨC THANH TOÁN ============
const listPaymentMethods = async (req, res) => {
    try {
        const userId = req.user.id;

        const methods = await PaymentMethod.find({ user: userId }).sort({ isDefault: -1, createdAt: -1 });

        return res.status(200).json({
            message: 'Lấy danh sách phương thức thanh toán thành công',
            paymentMethods: methods,
            total: methods.length
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ THÊM PHƯƠNG THỨC THANH TOÁN ============
const addPaymentMethod = async (req, res) => {
    try {
        const userId = req.user.id;
        const { type, name, accountNumber, bankName, isDefault } = req.body;

        if (!type || !name) {
            return res.status(400).json({ message: 'Vui lòng cung cấp loại và tên phương thức thanh toán' });
        }

        // Nếu đặt làm mặc định → bỏ mặc định của các phương thức khác
        if (isDefault) {
            await PaymentMethod.updateMany({ user: userId }, { isDefault: false });
        }

        const method = await PaymentMethod.create({
            user: userId,
            type,
            name,
            accountNumber: accountNumber || '',
            bankName: bankName || '',
            isDefault: isDefault || false
        });

        return res.status(201).json({
            message: 'Thêm phương thức thanh toán thành công',
            paymentMethod: method
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ XÓA PHƯƠNG THỨC THANH TOÁN ============
const deletePaymentMethod = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id } = req.params;

        const method = await PaymentMethod.findOneAndDelete({ _id: id, user: userId });

        if (!method) {
            return res.status(404).json({ message: 'Không tìm thấy phương thức thanh toán' });
        }

        return res.status(200).json({
            message: 'Xóa phương thức thanh toán thành công'
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    listPaymentMethods,
    addPaymentMethod,
    deletePaymentMethod
};


const mongoose = require('mongoose');
const Discount = require('../../models/Discount');
const { parsePagination, parseSort } = require('../../utils/pagination');
const { buildRegexQuery } = require('../../utils/query');

const listDiscounts = async (req, res) => {
    try {
        const { q, status } = req.query;
        const { page, limit, skip } = parsePagination(req.query);
        const sort = parseSort(req.query.sort, { createdAt: -1 });

        const filter = {};
        if (status) filter.status = status;
        const rx = buildRegexQuery(q);
        if (rx) {
            filter.$or = [{ code: rx }, { description: rx }];
        }

        const [discounts, total] = await Promise.all([
            Discount.find(filter).sort(sort).skip(skip).limit(limit),
            Discount.countDocuments(filter)
        ]);

        return res.status(200).json({
            message: 'Admin list discounts',
            discounts,
            pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const createDiscount = async (req, res) => {
    try {
        const {
            code,
            description,
            discountType,
            discountValue,
            maxDiscountAmount,
            minOrderValue,
            validFrom,
            validTo,
            usageLimit,
            status,
            applicableUsers
        } = req.body;

        if (!code || discountValue == null || !validTo) {
            return res.status(400).json({ message: 'Thiếu field bắt buộc: code, discountValue, validTo' });
        }
        if (!['percent', 'fixed'].includes(discountType || 'fixed')) {
            return res.status(400).json({ message: "discountType phải là 'percent' hoặc 'fixed'" });
        }

        const discount = await Discount.create({
            code: code.toUpperCase(),
            description: description || '',
            discountType: discountType || 'fixed',
            discountValue,
            maxDiscountAmount: maxDiscountAmount ?? null,
            minOrderValue: minOrderValue ?? 0,
            validFrom: validFrom ? new Date(validFrom) : new Date(),
            validTo: new Date(validTo),
            usageLimit: usageLimit ?? 100,
            status: status || 'active',
            applicableUsers: Array.isArray(applicableUsers) ? applicableUsers : (applicableUsers ? [applicableUsers] : [])
        });

        return res.status(201).json({ message: 'Tạo discount thành công', discount });
    } catch (error) {
        // Handle unique code
        if (error?.code === 11000) {
            return res.status(400).json({ message: 'Code đã tồn tại' });
        }
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateDiscount = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Discount id không hợp lệ' });
        }
        const patch = { ...req.body };
        if (patch.code) patch.code = patch.code.toUpperCase();
        if (patch.validFrom) patch.validFrom = new Date(patch.validFrom);
        if (patch.validTo) patch.validTo = new Date(patch.validTo);
        if (patch.applicableUsers && !Array.isArray(patch.applicableUsers)) {
            patch.applicableUsers = [patch.applicableUsers];
        }

        const discount = await Discount.findByIdAndUpdate(id, { $set: patch }, { new: true });
        if (!discount) return res.status(404).json({ message: 'Không tìm thấy discount' });

        return res.status(200).json({ message: 'Cập nhật discount thành công', discount });
    } catch (error) {
        if (error?.code === 11000) {
            return res.status(400).json({ message: 'Code đã tồn tại' });
        }
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateDiscountStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Discount id không hợp lệ' });
        }
        if (!['active', 'expired', 'disabled'].includes(status)) {
            return res.status(400).json({ message: "status phải là 'active'|'expired'|'disabled'" });
        }

        const discount = await Discount.findByIdAndUpdate(id, { $set: { status } }, { new: true });
        if (!discount) return res.status(404).json({ message: 'Không tìm thấy discount' });

        return res.status(200).json({ message: 'Cập nhật status discount thành công', discount });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    listDiscounts,
    createDiscount,
    updateDiscount,
    updateDiscountStatus
};


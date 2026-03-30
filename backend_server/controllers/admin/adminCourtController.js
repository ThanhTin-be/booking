const mongoose = require('mongoose');
const Court = require('../../models/Court');
const SubCourt = require('../../models/SubCourt');
const TimeSlot = require('../../models/TimeSlot');
const { parsePagination, parseSort } = require('../../utils/pagination');
const { buildRegexQuery } = require('../../utils/query');

function generateTimeSlots(openTime, closeTime) {
    const slots = [];
    let [h, m] = openTime.split(':').map(Number);
    const [closeH, closeM] = closeTime.split(':').map(Number);

    while (h < closeH || (h === closeH && m < closeM)) {
        const start = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
        m += 30;
        if (m >= 60) { h += 1; m -= 60; }
        const end = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
        slots.push({ start, end });
    }
    return slots;
}

// ============ COURTS ============
const listCourts = async (req, res) => {
    try {
        const { q, status, category } = req.query;
        const { page, limit, skip } = parsePagination(req.query);
        const sort = parseSort(req.query.sort, { createdAt: -1 });

        const filter = {};
        if (status) filter.status = status;
        if (category) filter.category = category;

        const rx = buildRegexQuery(q);
        if (rx) {
            filter.$or = [
                { name: rx },
                { address: rx },
                { category: rx },
                { tags: rx }
            ];
        }

        const [courts, total] = await Promise.all([
            Court.find(filter).skip(skip).limit(limit).sort(sort),
            Court.countDocuments(filter)
        ]);

        return res.status(200).json({
            message: 'Admin list courts',
            courts,
            pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const createCourt = async (req, res) => {
    try {
        const {
            name, description, address, category,
            pricePerHour, pricePerSlot,
            images, logoUrl,
            openTime, closeTime,
            tags, amenities,
            location
        } = req.body;

        if (!name || !category || pricePerHour == null) {
            return res.status(400).json({ message: 'Thiếu field bắt buộc: name, category, pricePerHour' });
        }

        const court = await Court.create({
            name,
            description: description || '',
            address: address || '',
            category,
            pricePerHour,
            pricePerSlot: pricePerSlot ?? 50000,
            images: Array.isArray(images) ? images : (images ? [images] : []),
            logoUrl: logoUrl || '',
            openTime: openTime || '06:00',
            closeTime: closeTime || '22:00',
            tags: Array.isArray(tags) ? tags : (tags ? [tags] : []),
            amenities: Array.isArray(amenities) ? amenities : (amenities ? [amenities] : []),
            location: location && typeof location === 'object' ? location : undefined
        });

        return res.status(201).json({ message: 'Tạo court thành công', court });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateCourt = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Court id không hợp lệ' });
        }

        const patch = { ...req.body };
        if (patch.images && !Array.isArray(patch.images)) patch.images = [patch.images];
        if (patch.tags && !Array.isArray(patch.tags)) patch.tags = [patch.tags];
        if (patch.amenities && !Array.isArray(patch.amenities)) patch.amenities = [patch.amenities];

        const court = await Court.findByIdAndUpdate(id, { $set: patch }, { new: true });
        if (!court) return res.status(404).json({ message: 'Không tìm thấy court' });

        return res.status(200).json({ message: 'Cập nhật court thành công', court });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateCourtStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Court id không hợp lệ' });
        }
        if (!['active', 'maintenance'].includes(status)) {
            return res.status(400).json({ message: "status phải là 'active' hoặc 'maintenance'" });
        }

        const court = await Court.findByIdAndUpdate(id, { $set: { status } }, { new: true });
        if (!court) return res.status(404).json({ message: 'Không tìm thấy court' });

        return res.status(200).json({ message: 'Cập nhật trạng thái court thành công', court });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ SUB COURTS ============
const listSubCourts = async (req, res) => {
    try {
        const { courtId } = req.params;
        if (!mongoose.Types.ObjectId.isValid(courtId)) {
            return res.status(400).json({ message: 'courtId không hợp lệ' });
        }
        const [court, subCourts] = await Promise.all([
            Court.findById(courtId),
            SubCourt.find({ court: courtId }).sort({ createdAt: -1 })
        ]);
        if (!court) return res.status(404).json({ message: 'Không tìm thấy court' });

        return res.status(200).json({ message: 'Admin list subCourts', court, subCourts });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const createSubCourt = async (req, res) => {
    try {
        const { courtId } = req.params;
        const { name, type, pricePerSlot, status } = req.body;
        if (!mongoose.Types.ObjectId.isValid(courtId)) {
            return res.status(400).json({ message: 'courtId không hợp lệ' });
        }
        if (!name) return res.status(400).json({ message: 'Thiếu name' });

        const court = await Court.findById(courtId);
        if (!court) return res.status(404).json({ message: 'Không tìm thấy court' });

        const subCourt = await SubCourt.create({
            court: courtId,
            name,
            type: type || 'standard',
            pricePerSlot: pricePerSlot ?? 0,
            status: status || 'active'
        });

        return res.status(201).json({ message: 'Tạo subCourt thành công', subCourt });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateSubCourt = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'SubCourt id không hợp lệ' });
        }
        const patch = { ...req.body };
        const subCourt = await SubCourt.findByIdAndUpdate(id, { $set: patch }, { new: true });
        if (!subCourt) return res.status(404).json({ message: 'Không tìm thấy subCourt' });

        return res.status(200).json({ message: 'Cập nhật subCourt thành công', subCourt });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateSubCourtStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'SubCourt id không hợp lệ' });
        }
        if (!['active', 'maintenance'].includes(status)) {
            return res.status(400).json({ message: "status phải là 'active' hoặc 'maintenance'" });
        }

        const subCourt = await SubCourt.findByIdAndUpdate(id, { $set: { status } }, { new: true });
        if (!subCourt) return res.status(404).json({ message: 'Không tìm thấy subCourt' });
        return res.status(200).json({ message: 'Cập nhật trạng thái subCourt thành công', subCourt });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ TIMESLOTS ============
const getCourtTimeSlotsByDate = async (req, res) => {
    try {
        const { courtId } = req.params;
        const { date } = req.query;
        if (!mongoose.Types.ObjectId.isValid(courtId)) {
            return res.status(400).json({ message: 'courtId không hợp lệ' });
        }
        if (!date) return res.status(400).json({ message: 'Thiếu date (YYYY-MM-DD)' });

        const [court, subCourts, timeSlots] = await Promise.all([
            Court.findById(courtId),
            SubCourt.find({ court: courtId }).sort({ name: 1 }),
            TimeSlot.find({ court: courtId, date }).populate('subCourt', 'name').sort({ subCourt: 1, startTime: 1 })
        ]);
        if (!court) return res.status(404).json({ message: 'Không tìm thấy court' });

        return res.status(200).json({ message: 'Admin get timeslots', court, subCourts, timeSlots, date });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const bulkGenerateTimeSlots = async (req, res) => {
    try {
        const { courtId } = req.params;
        const { date, mode } = req.body; // mode: 'keep' | 'replace'
        if (!mongoose.Types.ObjectId.isValid(courtId)) {
            return res.status(400).json({ message: 'courtId không hợp lệ' });
        }
        if (!date) return res.status(400).json({ message: 'Thiếu date (YYYY-MM-DD)' });

        const court = await Court.findById(courtId);
        if (!court) return res.status(404).json({ message: 'Không tìm thấy court' });

        const subCourts = await SubCourt.find({ court: courtId, status: 'active' }).sort({ name: 1 });
        if (!subCourts.length) return res.status(400).json({ message: 'Court chưa có subCourts active' });

        const slotTimes = generateTimeSlots(court.openTime || '06:00', court.closeTime || '22:00');

        if ((mode || 'keep') === 'replace') {
            // only delete slots that are not booked
            await TimeSlot.deleteMany({ court: courtId, date, status: { $ne: 'booked' } });
        }

        // Create missing slots only
        const existing = await TimeSlot.find({ court: courtId, date }).select('subCourt startTime endTime');
        const existingKey = new Set(existing.map(s => `${s.subCourt.toString()}|${s.startTime}|${s.endTime}`));

        const toInsert = [];
        for (const sc of subCourts) {
            const price = sc.pricePerSlot && sc.pricePerSlot > 0 ? sc.pricePerSlot : (court.pricePerSlot || 50000);
            for (const t of slotTimes) {
                const key = `${sc._id.toString()}|${t.start}|${t.end}`;
                if (existingKey.has(key)) continue;
                toInsert.push({
                    court: courtId,
                    subCourt: sc._id,
                    date,
                    startTime: t.start,
                    endTime: t.end,
                    status: 'available',
                    price
                });
            }
        }

        if (toInsert.length) await TimeSlot.insertMany(toInsert);

        const timeSlots = await TimeSlot.find({ court: courtId, date })
            .populate('subCourt', 'name')
            .sort({ subCourt: 1, startTime: 1 });

        return res.status(200).json({
            message: 'Bulk generate timeslots thành công',
            inserted: toInsert.length,
            date,
            court: { id: court._id, name: court.name },
            timeSlots
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const updateTimeSlot = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, price } = req.body;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'TimeSlot id không hợp lệ' });
        }

        const patch = {};
        if (status != null) {
            if (!['available', 'booked', 'locked'].includes(status)) {
                return res.status(400).json({ message: "status phải là 'available'|'booked'|'locked'" });
            }
            patch.status = status;
        }
        if (price != null) {
            const p = Number(price);
            if (Number.isNaN(p) || p < 0) return res.status(400).json({ message: 'price không hợp lệ' });
            patch.price = p;
        }

        const ts = await TimeSlot.findById(id);
        if (!ts) return res.status(404).json({ message: 'Không tìm thấy timeslot' });

        if (ts.status === 'booked' && patch.status && patch.status !== 'booked') {
            return res.status(400).json({ message: 'Không thể đổi status của slot booked bằng admin override' });
        }

        const updated = await TimeSlot.findByIdAndUpdate(id, { $set: patch }, { new: true })
            .populate('subCourt', 'name');

        return res.status(200).json({ message: 'Cập nhật timeslot thành công', timeSlot: updated });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ UPLOAD COURT IMAGES ============
const uploadCourtImages = async (req, res) => {
    try {
        const urls = [];

        // Xử lý images (nhiều file)
        if (req.files && req.files.images) {
            for (const file of req.files.images) {
                urls.push(`/uploads/courts/${file.filename}`);
            }
        }

        // Xử lý logo (1 file)
        let logoUrl = null;
        if (req.files && req.files.logo && req.files.logo.length > 0) {
            logoUrl = `/uploads/courts/${req.files.logo[0].filename}`;
        }

        return res.status(200).json({
            message: 'Upload ảnh thành công',
            images: urls,
            logoUrl
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    listCourts,
    createCourt,
    updateCourt,
    updateCourtStatus,
    listSubCourts,
    createSubCourt,
    updateSubCourt,
    updateSubCourtStatus,
    getCourtTimeSlotsByDate,
    bulkGenerateTimeSlots,
    updateTimeSlot,
    uploadCourtImages
};

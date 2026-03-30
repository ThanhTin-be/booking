const Court = require('../models/Court');
const SubCourt = require('../models/SubCourt');
const TimeSlot = require('../models/TimeSlot');

// ============ LẤY DANH SÁCH TẤT CẢ SÂN ============
const getAllCourts = async (req, res) => {
    try {
        const { category, status, page = 1, limit = 20 } = req.query;

        const filter = {};
        if (category) filter.category = category;
        if (status) filter.status = status;
        else filter.status = 'active'; // Mặc định chỉ hiện sân active

        const courts = await Court.find(filter)
            .skip((page - 1) * limit)
            .limit(parseInt(limit))
            .sort({ createdAt: -1 });

        const total = await Court.countDocuments(filter);

        return res.status(200).json({
            message: 'Lấy danh sách sân thành công',
            courts,
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

// ============ LẤY CHI TIẾT 1 SÂN ============
const getCourtDetail = async (req, res) => {
    try {
        const court = await Court.findById(req.params.id);
        if (!court) {
            return res.status(404).json({ message: 'Không tìm thấy sân' });
        }

        // Lấy luôn danh sách sân con
        const subCourts = await SubCourt.find({ court: court._id, status: 'active' });

        return res.status(200).json({
            message: 'Lấy chi tiết sân thành công',
            court,
            subCourts
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ TÌM KIẾM SÂN ============
const searchCourts = async (req, res) => {
    try {
        const { keyword } = req.query;
        if (!keyword) {
            return res.status(400).json({ message: 'Vui lòng nhập từ khóa tìm kiếm' });
        }

        // Tìm kiếm bằng regex (hỗ trợ tiếng Việt tốt hơn $text)
        const courts = await Court.find({
            status: 'active',
            $or: [
                { name: { $regex: keyword, $options: 'i' } },
                { address: { $regex: keyword, $options: 'i' } },
                { category: { $regex: keyword, $options: 'i' } }
            ]
        }).limit(20);

        return res.status(200).json({
            message: 'Tìm kiếm thành công',
            courts,
            total: courts.length
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ LẤY SÂN GẦN ĐÂY ============
const getNearbyCourts = async (req, res) => {
    try {
        const { lat, lng, maxDistance = 5000 } = req.query; // maxDistance: mét

        if (!lat || !lng) {
            return res.status(400).json({ message: 'Vui lòng cung cấp tọa độ (lat, lng)' });
        }

        const courts = await Court.find({
            status: 'active',
            'location.coordinates': {
                $nearSphere: {
                    $geometry: {
                        type: 'Point',
                        coordinates: [parseFloat(lng), parseFloat(lat)]
                    },
                    $maxDistance: parseInt(maxDistance)
                }
            }
        }).limit(20);

        return res.status(200).json({
            message: 'Lấy sân gần đây thành công',
            courts,
            total: courts.length
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ LẤY DANH SÁCH SÂN CON ============
const getSubCourts = async (req, res) => {
    try {
        const { id } = req.params; // courtId

        const court = await Court.findById(id);
        if (!court) {
            return res.status(404).json({ message: 'Không tìm thấy sân' });
        }

        const subCourts = await SubCourt.find({ court: id, status: 'active' }).sort({ name: 1 });

        return res.status(200).json({
            message: 'Lấy danh sách sân con thành công',
            courtName: court.name,
            subCourts
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// ============ LẤY TRẠNG THÁI SLOT GIỜ ============
const getTimeSlots = async (req, res) => {
    try {
        const { id } = req.params; // courtId
        const { date } = req.query; // Format: YYYY-MM-DD

        if (!date) {
            return res.status(400).json({ message: 'Vui lòng chọn ngày (format: YYYY-MM-DD)' });
        }

        const court = await Court.findById(id);
        if (!court) {
            return res.status(404).json({ message: 'Không tìm thấy sân' });
        }

        // Lấy tất cả sân con
        const subCourts = await SubCourt.find({ court: id, status: 'active' }).sort({ name: 1 });

        // Lấy tất cả slots cho ngày đó
        let timeSlots = await TimeSlot.find({ court: id, date })
            .populate('subCourt', 'name')
            .sort({ subCourt: 1, startTime: 1 });

        // Nếu chưa có slot nào → tự động tạo slots cho tất cả sân con
        if (timeSlots.length === 0 && subCourts.length > 0) {
            const defaultSlots = [];
            const slotTimes = generateTimeSlots(court.openTime || '06:00', court.closeTime || '22:00');

            for (const sc of subCourts) {
                for (const slot of slotTimes) {
                    defaultSlots.push({
                        court: id,
                        subCourt: sc._id,
                        date,
                        startTime: slot.start,
                        endTime: slot.end,
                        status: 'available',
                        price: sc.pricePerSlot || court.pricePerSlot || 50000
                    });
                }
            }

            await TimeSlot.insertMany(defaultSlots);

            // Query lại
            timeSlots = await TimeSlot.find({ court: id, date })
                .populate('subCourt', 'name')
                .sort({ subCourt: 1, startTime: 1 });
        }

        // Đánh dấu slot đã qua giờ hiện tại (chỉ cho ngày hôm nay)
        const vnOptions = { timeZone: 'Asia/Ho_Chi_Minh' };
        const todayStr = new Date().toLocaleDateString('sv-SE', vnOptions); // "YYYY-MM-DD"
        let slotsResponse = timeSlots;

        if (date === todayStr) {
            const nowTime = new Date().toLocaleTimeString('en-GB', { ...vnOptions, hour: '2-digit', minute: '2-digit', hour12: false }); // "HH:mm"
            slotsResponse = timeSlots.map(slot => {
                const slotObj = slot.toObject();
                // Slot đã qua giờ và đang available → đánh dấu expired
                if (slotObj.startTime <= nowTime && slotObj.status === 'available') {
                    slotObj.status = 'expired';
                }
                return slotObj;
            });
        }

        return res.status(200).json({
            message: 'Lấy slot giờ thành công',
            court: { id: court._id, name: court.name },
            subCourts,
            timeSlots: slotsResponse,
            date
        });
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

// Hàm tạo danh sách khung giờ 30 phút
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

module.exports = {
    getAllCourts,
    getCourtDetail,
    searchCourts,
    getNearbyCourts,
    getSubCourts,
    getTimeSlots
};


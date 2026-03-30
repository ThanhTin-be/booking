/**
 * Script thêm sân cầu lông mới vào DB
 * Chạy: node api/seedBadmintonCourts.js
 */
const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const Court = require('../models/Court');
const SubCourt = require('../models/SubCourt');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/booking';

async function seedBadmintonCourts() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Kết nối MongoDB thành công');

        const newCourts = await Court.insertMany([
            // ===== QUẬN BÌNH THẠNH =====
            {
                name: 'Sân Cầu Lông Bạch Đằng',
                description: 'Sân cầu lông chuyên nghiệp với 8 sân tiêu chuẩn, hệ thống đèn LED hiện đại, sàn gỗ cao cấp.',
                address: '55 Bạch Đằng, P.2, Q.Bình Thạnh, TP.HCM',
                category: 'Cầu lông',
                pricePerHour: 90000,
                pricePerSlot: 45000,
                images: ['/uploads/courts/court_1773796615006_347.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '05:30',
                closeTime: '22:30',
                tags: ['Đơn ngày', 'Giờ vàng'],
                location: { type: 'Point', coordinates: [106.6946, 10.8036] },
                ratingAvg: 4.6,
                totalReviews: 185,
                amenities: ['wifi', 'parking', 'water', 'changing_room', 'lighting'],
                status: 'active'
            },
            {
                name: 'CLB Cầu Lông Thanh Đa',
                description: 'Câu lạc bộ cầu lông lâu đời tại Bình Thạnh, không gian thoáng mát, bãi giữ xe rộng rãi.',
                address: '120 Xô Viết Nghệ Tĩnh, P.21, Q.Bình Thạnh, TP.HCM',
                category: 'Cầu lông',
                pricePerHour: 80000,
                pricePerSlot: 40000,
                images: ['/uploads/courts/court_1773796631834_441.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '06:00',
                closeTime: '22:00',
                tags: ['Đơn ngày', 'Sự kiện'],
                location: { type: 'Point', coordinates: [106.7013, 10.8012] },
                ratingAvg: 4.4,
                totalReviews: 142,
                amenities: ['parking', 'water', 'lighting', 'cafeteria'],
                status: 'active'
            },

            // ===== QUẬN PHÚ NHUẬN =====
            {
                name: 'Sân Cầu Lông Phan Đăng Lưu',
                description: 'Sân cầu lông cao cấp ngay trung tâm Phú Nhuận, sàn thể thao chuyên dụng, máy lạnh toàn sân.',
                address: '238 Phan Đăng Lưu, P.3, Q.Phú Nhuận, TP.HCM',
                category: 'Cầu lông',
                pricePerHour: 110000,
                pricePerSlot: 55000,
                images: ['/uploads/courts/court_1773796615006_347.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '05:00',
                closeTime: '23:00',
                tags: ['VIP', 'Mái che'],
                location: { type: 'Point', coordinates: [106.6838, 10.7975] },
                ratingAvg: 4.8,
                totalReviews: 267,
                amenities: ['wifi', 'parking', 'water', 'air_conditioning', 'pro_shop', 'changing_room'],
                status: 'active'
            },
            {
                name: 'CLB Cầu Lông Hoàng Văn Thụ',
                description: 'Câu lạc bộ cầu lông phong trào Phú Nhuận, giá cả hợp lý, phù hợp mọi trình độ.',
                address: '65 Hoàng Văn Thụ, P.8, Q.Phú Nhuận, TP.HCM',
                category: 'Cầu lông',
                pricePerHour: 75000,
                pricePerSlot: 38000,
                images: ['/uploads/courts/court_1773796631834_441.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '06:00',
                closeTime: '22:00',
                tags: ['Đơn ngày', 'Giờ vàng'],
                location: { type: 'Point', coordinates: [106.6752, 10.7998] },
                ratingAvg: 4.3,
                totalReviews: 98,
                amenities: ['parking', 'water', 'lighting'],
                status: 'active'
            },

            // ===== QUẬN 1 =====
            {
                name: 'Sân Cầu Lông Nguyễn Du',
                description: 'Sân cầu lông VIP trung tâm Quận 1, trang thiết bị hiện đại, phòng thay đồ sang trọng.',
                address: '32 Nguyễn Du, P.Bến Nghé, Q.1, TP.HCM',
                category: 'Cầu lông',
                pricePerHour: 150000,
                pricePerSlot: 75000,
                images: ['/uploads/courts/court_1773796615006_347.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '06:00',
                closeTime: '23:00',
                tags: ['VIP', 'Sự kiện', 'Mái che'],
                location: { type: 'Point', coordinates: [106.6958, 10.7810] },
                ratingAvg: 4.9,
                totalReviews: 350,
                amenities: ['wifi', 'parking', 'water', 'air_conditioning', 'changing_room', 'pro_shop', 'cafeteria'],
                status: 'active'
            },
            {
                name: 'CLB Cầu Lông Tao Đàn',
                description: 'Câu lạc bộ cầu lông nổi tiếng trong công viên Tao Đàn, không gian xanh mát, nhiều cây xanh.',
                address: 'Công viên Tao Đàn, P.Bến Thành, Q.1, TP.HCM',
                category: 'Cầu lông',
                pricePerHour: 120000,
                pricePerSlot: 60000,
                images: ['/uploads/courts/court_1773796631834_441.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '05:00',
                closeTime: '21:30',
                tags: ['Đơn ngày', 'Sự kiện'],
                location: { type: 'Point', coordinates: [106.6913, 10.7752] },
                ratingAvg: 4.7,
                totalReviews: 420,
                amenities: ['parking', 'water', 'lighting', 'changing_room'],
                status: 'active'
            }
        ]);
        console.log(`🏟️  Đã tạo ${newCourts.length} sân cầu lông mới`);

        // ====== TẠO SÂN CON ======
        const subCourtData = [];
        for (const court of newCourts) {
            for (let i = 1; i <= 8; i++) {
                subCourtData.push({
                    court: court._id,
                    name: `Sân ${i}`,
                    type: i <= 2 ? 'vip' : 'standard',
                    pricePerSlot: i <= 2 ? court.pricePerSlot * 1.5 : court.pricePerSlot,
                    status: 'active'
                });
            }
        }
        const subCourts = await SubCourt.insertMany(subCourtData);
        console.log(`🏓  Đã tạo ${subCourts.length} sân con`);

        console.log('\n🎉 Seed sân cầu lông thành công!');
        console.log('==============================');
        for (const c of newCourts) {
            console.log(`  • ${c.name} — ${c.address}`);
        }
        console.log('==============================');

        process.exit(0);
    } catch (error) {
        console.error('❌ Lỗi:', error.message);
        process.exit(1);
    }
}

seedBadmintonCourts();

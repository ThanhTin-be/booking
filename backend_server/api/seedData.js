/**
 * Script seed dữ liệu mẫu cho Database
 * Chạy: node api/seedData.js
 */
const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const Court = require('../models/Court');
const SubCourt = require('../models/SubCourt');
const Discount = require('../models/Discount');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/booking';

async function seedData() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Kết nối MongoDB thành công');

        // ====== XÓA DỮ LIỆU CŨ ======
        await Court.deleteMany({});
        await SubCourt.deleteMany({});
        await Discount.deleteMany({});
        console.log('🗑️  Đã xóa dữ liệu cũ');

        // ====== SEED COURTS ======
        const courts = await Court.insertMany([
            {
                name: 'PM PICKLEBALL',
                description: 'Sân Pickleball chất lượng cao, mái che, đèn LED.',
                address: '104 Tân Sơn, P.15, Q.Tân Bình, TP.HCM',
                category: 'Pickleball',
                pricePerHour: 100000,
                pricePerSlot: 50000,
                images: ['/uploads/courts/court_1773796597658_788.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '05:00',
                closeTime: '23:00',
                tags: ['Đơn ngày', 'Sự kiện'],
                location: { type: 'Point', coordinates: [106.6516, 10.8066] },
                ratingAvg: 4.5,
                totalReviews: 120,
                amenities: ['wifi', 'parking', 'water', 'lighting'],
                status: 'active'
            },
            {
                name: 'SÂN BÓNG ĐÁ PM SPORT',
                description: 'Sân bóng đá mini 5 người, cỏ nhân tạo nhập khẩu.',
                address: '104 Đ. Tân Sơn, P.15, Tân Bình, TP.HCM',
                category: 'Bóng đá',
                pricePerHour: 200000,
                pricePerSlot: 100000,
                images: ['/uploads/courts/court_1773796608350_378.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '00:00',
                closeTime: '24:00',
                tags: ['Đơn ngày'],
                location: { type: 'Point', coordinates: [106.6520, 10.8070] },
                ratingAvg: 4.2,
                totalReviews: 85,
                amenities: ['parking', 'water', 'shower'],
                status: 'active'
            },
            {
                name: 'CLB Cầu Lông Chiến Thắng',
                description: 'Câu lạc bộ cầu lông lâu đời, sân gỗ chất lượng.',
                address: '45 Phạm Văn Đồng, Thủ Đức, TP.HCM',
                category: 'Cầu lông',
                pricePerHour: 80000,
                pricePerSlot: 40000,
                images: ['/uploads/courts/court_1773796615006_347.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '06:00',
                closeTime: '22:00',
                tags: ['Giờ vàng'],
                location: { type: 'Point', coordinates: [106.7142, 10.8540] },
                ratingAvg: 4.7,
                totalReviews: 200,
                amenities: ['wifi', 'parking', 'water', 'changing_room'],
                status: 'active'
            },
            {
                name: 'Sân Tennis Lan Anh',
                description: 'Sân tennis tiêu chuẩn quốc tế, bề mặt cứng.',
                address: '291 Cách Mạng Tháng 8, Q.10, TP.HCM',
                category: 'Tennis',
                pricePerHour: 150000,
                pricePerSlot: 75000,
                images: ['/uploads/courts/court_1773796624431_819.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '05:00',
                closeTime: '22:00',
                tags: ['VIP', 'Mái che'],
                location: { type: 'Point', coordinates: [106.6730, 10.7786] },
                ratingAvg: 4.3,
                totalReviews: 95,
                amenities: ['wifi', 'parking', 'lighting', 'pro_shop'],
                status: 'active'
            },
            {
                name: 'Sân Cầu Lông Quận 7',
                description: 'Sân cầu lông hiện đại khu vực Phú Mỹ Hưng.',
                address: '123 Nguyễn Lương Bằng, Phú Mỹ Hưng, Q.7, TP.HCM',
                category: 'Cầu lông',
                pricePerHour: 120000,
                pricePerSlot: 60000,
                images: ['/uploads/courts/court_1773796631834_441.jpg'],
                logoUrl: '/uploads/courts/logo_1773796597659_633.png',
                openTime: '06:00',
                closeTime: '22:30',
                tags: ['VIP', 'Sự kiện', 'Đơn ngày'],
                location: { type: 'Point', coordinates: [106.7215, 10.7295] },
                ratingAvg: 4.8,
                totalReviews: 310,
                amenities: ['wifi', 'parking', 'water', 'changing_room', 'air_conditioning'],
                status: 'active'
            }
        ]);
        console.log(`🏟️  Đã tạo ${courts.length} sân`);

        // ====== SEED SUB-COURTS ======
        const subCourtData = [];
        for (const court of courts) {
            const count = court.category === 'Bóng đá' ? 4 : 10;
            for (let i = 1; i <= count; i++) {
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

        // ====== SEED DISCOUNTS ======
        const discounts = await Discount.insertMany([
            {
                code: 'WELCOME20',
                description: 'Giảm 20.000đ cho khách hàng lần đầu đặt sân trên ứng dụng.',
                discountType: 'fixed',
                discountValue: 20000,
                minOrderValue: 50000,
                validFrom: new Date('2026-01-01'),
                validTo: new Date('2026-12-31'),
                usageLimit: 500,
                usedCount: 0,
                status: 'active'
            },
            {
                code: 'HAPPYHOUR',
                description: 'Giảm 10% khi đặt sân từ 10:00 - 14:00 ngày thường.',
                discountType: 'percent',
                discountValue: 10,
                maxDiscountAmount: 50000,
                minOrderValue: 100000,
                validFrom: new Date('2026-01-01'),
                validTo: new Date('2026-06-30'),
                usageLimit: 200,
                usedCount: 0,
                status: 'active'
            },
            {
                code: 'LOYALTY50',
                description: 'Giảm 50.000đ cho đơn hàng từ 500.000đ trở lên.',
                discountType: 'fixed',
                discountValue: 50000,
                minOrderValue: 500000,
                validFrom: new Date('2026-01-01'),
                validTo: new Date('2026-12-31'),
                usageLimit: 100,
                usedCount: 0,
                status: 'active'
            },
            {
                code: 'KM30',
                description: 'Giảm 30% cho lần đầu đặt sân.',
                discountType: 'percent',
                discountValue: 30,
                maxDiscountAmount: 100000,
                minOrderValue: 100000,
                validFrom: new Date('2026-01-01'),
                validTo: new Date('2026-12-31'),
                usageLimit: 500,
                usedCount: 150,
                status: 'active'
            },
            {
                code: 'GIOTHANG',
                description: 'Giảm 20.000đ khung giờ vàng.',
                discountType: 'fixed',
                discountValue: 20000,
                minOrderValue: 50000,
                validFrom: new Date('2025-01-01'),
                validTo: new Date('2025-11-15'),
                usageLimit: 200,
                usedCount: 200,
                status: 'expired'
            }
        ]);
        console.log(`🎫  Đã tạo ${discounts.length} mã giảm giá`);

        console.log('\n🎉 Seed dữ liệu thành công!');
        console.log('==============================');
        console.log(`Sân: ${courts.length}`);
        console.log(`Sân con: ${subCourts.length}`);
        console.log(`Mã giảm giá: ${discounts.length}`);
        console.log('==============================');

        process.exit(0);
    } catch (error) {
        console.error('❌ Lỗi seed dữ liệu:', error.message);
        process.exit(1);
    }
}

seedData();


const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const os = require('os');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
const connectDB = require('./config/db');
const { startSlotCleanupJob } = require('./utils/slotCleanup');

// Tự động lấy IP máy hiện tại (WiFi / LAN)
function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

// 1. Cấu hình biến môi trường
dotenv.config();

// 2. Kết nối Database
connectDB();

// 3. Khởi tạo App Express
const app = express();

// 4. Middleware (Cho phép nhận JSON và CORS)
app.use(express.json()); 
app.use(cors());

// 4.1. Serve static files (uploaded avatars, images)
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));
// 4.2. Serve admin web UI (static)
const adminWebPath = path.join(__dirname, '../admin_web');
// Serve built assets explicitly (avoid SPA fallback catching them)
app.use('/admin/assets', express.static(path.join(adminWebPath, 'assets')));
// SPA fallback for any other GET under /admin/*
app.use('/admin', (req, res, next) => {
  if (req.method !== 'GET') return next();
  if (req.path.startsWith('/assets/')) return next();
  return res.sendFile(path.join(adminWebPath, 'index.html'));
});
app.get('/__admin_route_test', (req, res) => res.json({ ok: true }));

// 5. Swagger API Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument, {
    swaggerOptions: {
        url: '/swagger.json'
    }
}));
app.get('/swagger.json', (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.send(swaggerDocument);
});

// 5.1. Test Route
app.get('/', (req, res) => {
    res.send('API đang chạy ngon lành! 🚀');
});

// 5.2. API routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/courts', require('./routes/courtRoutes'));
app.use('/api/bookings', require('./routes/bookingRoutes'));
app.use('/api/payments', require('./routes/paymentRoutes'));
app.use('/api/wallet', require('./routes/walletRoutes'));
app.use('/api/wishlist', require('./routes/wishlistRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/discounts', require('./routes/discountRoutes'));
app.use('/api/payment-methods', require('./routes/paymentMethodRoutes'));
app.use('/api/vnpay', require('./routes/vnpayRoutes'));

// 5.3. Admin API routes (JWT + role=admin)
app.use('/api/admin', require('./routes/admin'));

// 6. Chạy Server - Lắng nghe trên 0.0.0.0 để cho phép thiết bị khác truy cập
const PORT = process.env.PORT || 5000;
const LOCAL_IP = getLocalIP();
app.listen(PORT, '0.0.0.0', () => {
    console.log('');
    console.log('  ╔══════════════════════════════════════════════════════════════╗');
    console.log(`  ║  ✅ Server đang chạy tại http://${LOCAL_IP}:${PORT}`);
    console.log(`  ║  📖 Docs:      http://${LOCAL_IP}:${PORT}/api-docs`);
    console.log(`  ║  🛠️  Admin UI:  http://${LOCAL_IP}:${PORT}/admin/`);
    console.log('  ╠══════════════════════════════════════════════════════════════╣');
    console.log('  ║  📱 Để app Flutter kết nối, cập nhật mobile_app/.env:');
    console.log(`  ║     API_BASE_URL=http://${LOCAL_IP}:${PORT}/api`);
    console.log('  ║');
    console.log('  ║  💡 Hoặc chạy: update-ip.bat (tự động cập nhật IP)');
    console.log('  ╚══════════════════════════════════════════════════════════════╝');
    console.log('');

    // Khởi động job tự động giải phóng slot hết hạn
    startSlotCleanupJob();
});

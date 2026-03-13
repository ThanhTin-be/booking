const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const os = require('os');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
const connectDB = require('./config/db');

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

// 6. Chạy Server - Lắng nghe trên 0.0.0.0 để cho phép thiết bị khác truy cập
const PORT = process.env.PORT || 5000;
const LOCAL_IP = getLocalIP();
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Server đang chạy tại http://${LOCAL_IP}:${PORT}`);
    console.log(`📖 Docs: http://${LOCAL_IP}:${PORT}/api-docs`);
    console.log(`📱 Điền vào mobile_app/.env:`);
    console.log(`   API_BASE_URL=http://${LOCAL_IP}:${PORT}/api`);
});

const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
const connectDB = require('./config/db');

// 1. Cấu hình biến môi trường
dotenv.config();

// 2. Kết nối Database
connectDB();

// 3. Khởi tạo App Express
const app = express();

// 4. Middleware (Cho phép nhận JSON và CORS)
app.use(express.json()); 
app.use(cors());

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

// 6. Chạy Server - Lắng nghe trên 0.0.0.0 để cho phép thiết bị khác truy cập
const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server đang chạy tại http://192.168.1.236:${PORT}`);
    console.log(`Docs: http://192.168.1.236:${PORT}/api-docs`);
});

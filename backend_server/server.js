const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
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

// 5. Test Route (Để kiểm tra server sống hay chết)
app.get('/', (req, res) => {
    res.send('API đang chạy ngon lành!');
});

// 6. Chạy Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server đang chạy ở cổng ${PORT}`);
});
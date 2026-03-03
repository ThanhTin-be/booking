const jwt = require('jsonwebtoken');

// Middleware xác thực JWT Token
const authMiddleware = (req, res, next) => {
    try {
        // Lấy token từ header Authorization
        const token = req.headers.authorization?.split(' ')[1]; // Bearer <token>
        
        if (!token) {
            return res.status(401).json({ 
                message: 'Không có token, vui lòng đăng nhập' 
            });
        }
        
        // Xác minh token
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key');
        req.user = decoded; // Lưu thông tin user vào request
        next();
    } catch (error) {
        return res.status(403).json({ 
            message: 'Token không hợp lệ hoặc đã hết hạn',
            error: error.message 
        });
    }
};

// Middleware kiểm tra role admin
const adminMiddleware = (req, res, next) => {
    if (req.user?.role !== 'admin') {
        return res.status(403).json({ 
            message: 'Bạn không có quyền truy cập' 
        });
    }
    next();
};

module.exports = { authMiddleware, adminMiddleware };

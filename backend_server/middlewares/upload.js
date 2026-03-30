const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Đảm bảo folder tồn tại
const courtsUploadDir = path.join(__dirname, '../public/uploads/courts');
if (!fs.existsSync(courtsUploadDir)) {
    fs.mkdirSync(courtsUploadDir, { recursive: true });
}

// Multer config cho court images
const courtStorage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, courtsUploadDir);
    },
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        const prefix = file.fieldname === 'logo' ? 'logo' : 'court';
        cb(null, `${prefix}_${Date.now()}_${Math.round(Math.random() * 1000)}${ext}`);
    }
});

const fileFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp/;
    const extOk = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimeOk = allowedTypes.test(file.mimetype);
    if (extOk && mimeOk) {
        cb(null, true);
    } else {
        cb(new Error('Chỉ cho phép file ảnh (jpg, jpeg, png, gif, webp)'));
    }
};

const courtUpload = multer({
    storage: courtStorage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB per file
    fileFilter
});

module.exports = { courtUpload };

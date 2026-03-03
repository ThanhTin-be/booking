# 🔐 Authentication API Documentation

## Base URL
```
http://localhost:5000/api/auth
```

---

## 📝 Endpoints

### 1. ĐĂNG KÝ (Register)
**POST** `/register`

**Request Body:**
```json
{
    "fullName": "Nguyễn Văn A",
    "email": "user@example.com",
    "password": "password123",
    "confirmPassword": "password123"
}
```

**Success Response (201):**
```json
{
    "message": "Đăng ký thành công",
    "user": {
        "id": "64a5f3c1d7e9a2b3c4d5e6f7",
        "fullName": "Nguyễn Văn A",
        "email": "user@example.com",
        "role": "customer"
    }
}
```

**Error Response (400/500):**
```json
{
    "message": "Email đã được đăng ký"
}
```

---

### 2. ĐĂNG NHẬP (Login)
**POST** `/login`

**Request Body:**
```json
{
    "email": "user@example.com",
    "password": "password123"
}
```

**Success Response (200):**
```json
{
    "message": "Đăng nhập thành công",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": "64a5f3c1d7e9a2b3c4d5e6f7",
        "fullName": "Nguyễn Văn A",
        "email": "user@example.com",
        "role": "customer"
    }
}
```

**Error Response (401):**
```json
{
    "message": "Email hoặc mật khẩu không đúng"
}
```

---

### 3. LẤY THÔNG TIN USER HIỆN TẠI (Get Current User)
**GET** `/me`

**Headers:**
```
Authorization: Bearer <your_token_here>
```

**Success Response (200):**
```json
{
    "message": "Lấy thông tin thành công",
    "user": {
        "_id": "64a5f3c1d7e9a2b3c4d5e6f7",
        "fullName": "Nguyễn Văn A",
        "email": "user@example.com",
        "role": "customer",
        "avatar": "",
        "phone": "",
        "createdAt": "2026-02-04T10:30:00.000Z",
        "updatedAt": "2026-02-04T10:30:00.000Z"
    }
}
```

---

### 4. ĐĂNG XUẤT (Logout)
**POST** `/logout`

**Headers:**
```
Authorization: Bearer <your_token_here>
```

**Success Response (200):**
```json
{
    "message": "Đăng xuất thành công"
}
```

---

## 🔑 JWT Token
- **Hết hạn sau:** 7 ngày
- **Cách sử dụng:** Thêm token vào header `Authorization: Bearer <token>`
- **Secret Key:** Được định nghĩa trong `.env` file (JWT_SECRET)

---

## ⚙️ Cài đặt

### 1. Cài đặt packages
```bash
npm install
```

### 2. Tạo file `.env`
```
MONGO_URI=mongodb://localhost:27017/booking
JWT_SECRET=booking_secret_key_2025
PORT=5000
```

### 3. Chạy server
```bash
npm run dev     # Chạy với nodemon (phát triển)
npm start       # Chạy bình thường
```

---

## 🧪 Testing với Postman

### Register:
```
POST http://localhost:5000/api/auth/register
Content-Type: application/json

{
    "fullName": "Nguyễn Văn A",
    "email": "user@example.com",
    "password": "password123",
    "confirmPassword": "password123"
}
```

### Login:
```
POST http://localhost:5000/api/auth/login
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "password123"
}
```

### Get Current User:
```
GET http://localhost:5000/api/auth/me
Authorization: Bearer <token_from_login>
```

### Logout:
```
POST http://localhost:5000/api/auth/logout
Authorization: Bearer <token_from_login>
```

---

## 🛡️ Security Features
✅ Password hashing với bcryptjs (10 rounds)  
✅ JWT Token Authentication  
✅ Email validation (unique)  
✅ Refresh Token support  
✅ Role-based access control (customer/admin)  
✅ Middleware protection cho routes  

---

## 📌 Error Codes
- **400** - Bad Request (missing fields, validation errors)
- **401** - Unauthorized (wrong credentials)
- **403** - Forbidden (invalid token, no permission)
- **404** - Not Found
- **500** - Server Error

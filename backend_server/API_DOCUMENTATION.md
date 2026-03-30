# 📖 API DOCUMENTATION — Badminton Booking App

> **Base URL:** `http://<SERVER_IP>:5000/api`  
> **Swagger UI:** `http://<SERVER_IP>:5000/api-docs`  
> **Auth:** Bearer Token (JWT) — Header: `Authorization: Bearer <token>`  
> 🔒 = Cần đăng nhập (gửi token)

---

## Mục lục

1. [Authentication](#1-authentication)
2. [User Profile](#2-user-profile)
3. [Courts](#3-courts)
4. [Bookings](#4-bookings)
5. [Payments](#5-payments)
6. [Wallet & Transactions](#6-wallet--transactions)
7. [Wishlist](#7-wishlist)
8. [Notifications](#8-notifications)
9. [Discounts](#9-discounts)
10. [Payment Methods](#10-payment-methods)

---

## 1. Authentication

### 1.1 Đăng ký
```
POST /api/auth/register
```
**Body:**
```json
{
  "fullName": "Thanh Tín",
  "email": "tin@gmail.com",
  "phone": "0909123456",
  "password": "123456",
  "confirmPassword": "123456"
}
```
**Response (201):**
```json
{
  "message": "Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản",
  "user": {
    "id": "665a...",
    "fullName": "Thanh Tín",
    "email": "tin@gmail.com",
    "role": "customer",
    "emailVerified": false
  }
}
```

---

### 1.2 Đăng nhập
```
POST /api/auth/login
```
**Body:**
```json
{
  "email": "tin@gmail.com",
  "password": "123456"
}
```
**Response (200):**
```json
{
  "message": "Đăng nhập thành công",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "665a...",
    "fullName": "Thanh Tín",
    "email": "tin@gmail.com",
    "role": "customer",
    "emailVerified": true
  }
}
```
**Response (400) — Chưa xác thực email:**
```json
{
  "message": "Vui lòng xác thực email trước khi đăng nhập",
  "requiresVerification": true,
  "email": "tin@gmail.com"
}
```

---

### 1.3 Xác thực email
```
POST /api/auth/verify-email
```
**Body:**
```json
{
  "email": "tin@gmail.com",
  "verificationCode": "123456"
}
```
**Response (200):**
```json
{
  "message": "Xác thực email thành công! Bạn có thể đăng nhập ngay",
  "user": { "id": "665a...", "fullName": "Thanh Tín", "email": "tin@gmail.com", "emailVerified": true }
}
```

---

### 1.4 Gửi lại mã xác thực
```
POST /api/auth/resend-code
```
**Body:**
```json
{ "email": "tin@gmail.com" }
```
**Response (200):**
```json
{ "message": "Mã xác thực mới đã được gửi đến email của bạn" }
```

---

### 1.5 Quên mật khẩu
```
POST /api/auth/forgot-password
```
**Body:**
```json
{ "email": "tin@gmail.com" }
```
**Response (200):**
```json
{ "message": "Mã đặt lại mật khẩu đã được gửi đến email của bạn" }
```

---

### 1.6 Đặt lại mật khẩu
```
POST /api/auth/reset-password
```
**Body:**
```json
{
  "email": "tin@gmail.com",
  "code": "654321",
  "newPassword": "newpass123"
}
```
**Response (200):**
```json
{ "message": "Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới." }
```

---

### 1.7 Lấy thông tin user hiện tại 🔒
```
GET /api/auth/me
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Lấy thông tin thành công",
  "user": {
    "_id": "665a...",
    "fullName": "Thanh Tín",
    "email": "tin@gmail.com",
    "phone": "0909123456",
    "role": "customer",
    "avatar": "/uploads/avatar_xxx.jpg",
    "address": "",
    "emailVerified": true
  }
}
```

---

### 1.8 Đăng xuất 🔒
```
POST /api/auth/logout
Authorization: Bearer <token>
```
**Response (200):**
```json
{ "message": "Đăng xuất thành công" }
```

---

## 2. User Profile

### 2.1 Cập nhật thông tin cá nhân 🔒
```
PUT /api/users/profile
Authorization: Bearer <token>
```
**Body (tất cả field đều optional):**
```json
{
  "fullName": "Thanh Tín Updated",
  "phone": "0909999888",
  "email": "tin@gmail.com",
  "address": "123 Nguyễn Văn A, Q.1, TP.HCM"
}
```
**Response (200):**
```json
{
  "message": "Cập nhật thông tin thành công",
  "user": {
    "_id": "665a...",
    "fullName": "Thanh Tín Updated",
    "phone": "0909999888",
    "email": "tin@gmail.com",
    "address": "123 Nguyễn Văn A, Q.1, TP.HCM"
  }
}
```

---

### 2.2 Upload avatar 🔒
```
POST /api/users/avatar
Authorization: Bearer <token>
Content-Type: multipart/form-data
```
**Form Data:**
| Field | Type | Mô tả |
|-------|------|--------|
| avatar | File | Ảnh jpg/png/gif, max 5MB |

**Response (200):**
```json
{
  "message": "Cập nhật avatar thành công",
  "avatar": "/uploads/avatar_665a_1234567890.jpg",
  "user": { "..." }
}
```

---

### 2.3 Lấy thông tin ví 🔒
```
GET /api/users/wallet
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Lấy thông tin ví thành công",
  "wallet": {
    "balance": 500000,
    "points": 50,
    "tier": "member",
    "role": "customer"
  }
}
```

---

## 3. Courts

### 3.1 Lấy danh sách sân
```
GET /api/courts?category=Cầu lông&status=active&page=1&limit=20
```
| Param | Mô tả | Mặc định |
|-------|--------|----------|
| category | Cầu lông / Bóng đá / Tennis / Pickleball | Tất cả |
| status | active / maintenance | active |
| page | Trang | 1 |
| limit | Số lượng / trang | 20 |

**Response (200):**
```json
{
  "message": "Lấy danh sách sân thành công",
  "courts": [
    {
      "_id": "665b...",
      "name": "CLB Cầu Lông Chiến Thắng",
      "address": "45 Phạm Văn Đồng, Thủ Đức",
      "category": "Cầu lông",
      "pricePerHour": 80000,
      "pricePerSlot": 40000,
      "images": ["https://..."],
      "logoUrl": "https://...",
      "openTime": "06:00",
      "closeTime": "22:00",
      "tags": ["Giờ vàng"],
      "ratingAvg": 4.7,
      "totalReviews": 200,
      "amenities": ["wifi", "parking"],
      "location": { "type": "Point", "coordinates": [106.7142, 10.8540] },
      "status": "active"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 5, "totalPages": 1 }
}
```

---

### 3.2 Chi tiết sân
```
GET /api/courts/:id
```
**Response (200):**
```json
{
  "message": "Lấy chi tiết sân thành công",
  "court": { "..." },
  "subCourts": [
    { "_id": "...", "name": "Sân 1", "type": "vip", "pricePerSlot": 60000, "status": "active" },
    { "_id": "...", "name": "Sân 2", "type": "standard", "pricePerSlot": 40000, "status": "active" }
  ]
}
```

---

### 3.3 Tìm kiếm sân
```
GET /api/courts/search?keyword=cầu lông
```
**Response (200):**
```json
{
  "message": "Tìm kiếm thành công",
  "courts": [ "..." ],
  "total": 2
}
```

---

### 3.4 Sân gần đây
```
GET /api/courts/nearby?lat=10.8066&lng=106.6516&maxDistance=5000
```
| Param | Bắt buộc | Mô tả |
|-------|----------|--------|
| lat | ✅ | Vĩ độ |
| lng | ✅ | Kinh độ |
| maxDistance | ❌ | Bán kính (mét), mặc định 5000 |

**Response (200):**
```json
{
  "message": "Lấy sân gần đây thành công",
  "courts": [ "..." ],
  "total": 3
}
```

---

### 3.5 Danh sách sân con
```
GET /api/courts/:id/sub-courts
```
**Response (200):**
```json
{
  "message": "Lấy danh sách sân con thành công",
  "courtName": "CLB Cầu Lông Chiến Thắng",
  "subCourts": [
    { "_id": "...", "name": "Sân 1", "type": "vip", "pricePerSlot": 60000 },
    { "_id": "...", "name": "Sân 2", "type": "standard", "pricePerSlot": 40000 }
  ]
}
```

---

### 3.6 Slot giờ theo ngày ⚡
```
GET /api/courts/:id/time-slots?date=2026-03-15
```
> ⚡ Nếu chưa có slot cho ngày đó → **tự động tạo** tất cả slot từ giờ mở cửa đến đóng cửa (mỗi slot 30 phút)

**Response (200):**
```json
{
  "message": "Lấy slot giờ thành công",
  "court": { "id": "665b...", "name": "CLB Cầu Lông Chiến Thắng" },
  "subCourts": [ "..." ],
  "timeSlots": [
    {
      "_id": "slot_id_1",
      "subCourt": { "_id": "...", "name": "Sân 1" },
      "date": "2026-03-15",
      "startTime": "06:00",
      "endTime": "06:30",
      "status": "available",
      "price": 40000
    },
    {
      "_id": "slot_id_2",
      "subCourt": { "_id": "...", "name": "Sân 1" },
      "date": "2026-03-15",
      "startTime": "06:30",
      "endTime": "07:00",
      "status": "booked",
      "price": 40000
    }
  ],
  "date": "2026-03-15"
}
```
> **status**: `available` (trống) | `booked` (đã đặt) | `locked` (khóa)

---

## 4. Bookings

### 4.1 Tạo booking 🔒
```
POST /api/bookings
Authorization: Bearer <token>
```
**Body:**
```json
{
  "courtId": "665b...",
  "subCourtId": "665c...",
  "date": "2026-03-15",
  "timeSlotIds": ["slot_id_1", "slot_id_2", "slot_id_3"],
  "paymentMethod": "bank",
  "discountCode": "WELCOME20",
  "contactName": "Thanh Tín",
  "contactPhone": "0909123456"
}
```
| Field | Bắt buộc | Mô tả |
|-------|----------|--------|
| courtId | ✅ | ID sân |
| subCourtId | ❌ | ID sân con |
| date | ✅ | Ngày (YYYY-MM-DD) |
| timeSlotIds | ✅ | Mảng ID các slot đã chọn |
| paymentMethod | ❌ | cash/bank/momo/wallet (mặc định: cash) |
| discountCode | ❌ | Mã giảm giá |
| contactName | ❌ | Tên liên hệ |
| contactPhone | ❌ | SĐT liên hệ |

**Response (201):**
```json
{
  "message": "Đặt sân thành công!",
  "booking": {
    "id": "booking_id",
    "bookingCode": "BK1001",
    "courtName": "CLB Cầu Lông Chiến Thắng",
    "date": "2026-03-15",
    "startTime": "17:30",
    "endTime": "19:00",
    "totalPrice": 120000,
    "discountAmount": 20000,
    "finalPrice": 100000,
    "paymentMethod": "bank",
    "status": "pending"
  }
}
```

---

### 4.2 Danh sách booking của tôi 🔒
```
GET /api/bookings?status=upcoming&page=1&limit=20
Authorization: Bearer <token>
```
| Param | Mô tả |
|-------|--------|
| status | `upcoming` (sắp tới) / `completed` / `cancelled` |
| page, limit | Phân trang |

**Response (200):**
```json
{
  "message": "Lấy danh sách vé thành công",
  "bookings": [
    {
      "_id": "...",
      "bookingCode": "BK1001",
      "court": { "_id": "...", "name": "PM PICKLEBALL", "address": "...", "images": ["..."] },
      "subCourt": { "_id": "...", "name": "Sân 5" },
      "date": "2026-03-15",
      "startTime": "17:30",
      "endTime": "19:00",
      "finalPrice": 150000,
      "status": "confirmed",
      "paymentMethod": "bank"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 3, "totalPages": 1 }
}
```

---

### 4.3 Chi tiết booking 🔒
```
GET /api/bookings/:id
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Lấy chi tiết booking thành công",
  "booking": {
    "_id": "...",
    "bookingCode": "BK1001",
    "court": { "name": "PM PICKLEBALL", "address": "..." },
    "subCourt": { "name": "Sân 5" },
    "date": "2026-03-15",
    "startTime": "17:30",
    "endTime": "19:00",
    "timeSlots": [
      { "startTime": "17:30", "endTime": "18:00", "price": 50000 },
      { "startTime": "18:00", "endTime": "18:30", "price": 50000 },
      { "startTime": "18:30", "endTime": "19:00", "price": 50000 }
    ],
    "totalPrice": 150000,
    "discountAmount": 0,
    "finalPrice": 150000,
    "discount": null,
    "status": "confirmed",
    "paymentMethod": "bank",
    "contactName": "Thanh Tín",
    "contactPhone": "0909123456"
  }
}
```

---

### 4.4 Hủy booking 🔒
```
PUT /api/bookings/:id/cancel
Authorization: Bearer <token>
```
> Chỉ hủy được khi status = `pending` hoặc `confirmed`

**Response (200):**
```json
{
  "message": "Hủy booking thành công",
  "booking": { "id": "...", "bookingCode": "BK1001", "status": "cancelled" }
}
```

---

## 5. Payments

### 5.1 Tạo yêu cầu thanh toán 🔒
```
POST /api/payments
Authorization: Bearer <token>
```
**Body:**
```json
{
  "bookingId": "booking_id",
  "method": "bank"
}
```
> Method: `cash` | `bank` | `momo` | `wallet`

**Response (201):**
```json
{
  "message": "Tạo yêu cầu thanh toán thành công",
  "payment": {
    "id": "payment_id",
    "amount": 150000,
    "method": "bank",
    "status": "pending",
    "transactionId": "PAY1710123456789123"
  }
}
```

---

### 5.2 Xác nhận thanh toán 🔒
```
PUT /api/payments/:id/confirm
Authorization: Bearer <token>
```
> Nếu method = `wallet` → tự động trừ tiền ví

**Response (200):**
```json
{
  "message": "Xác nhận thanh toán thành công",
  "payment": { "id": "payment_id", "status": "completed", "paidAt": "2026-03-15T10:30:00.000Z" }
}
```

---

### 5.3 Tạo mã QR thanh toán 🔒
```
GET /api/payments/:id/qr-code
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Tạo mã QR thành công",
  "qrCode": "data:image/png;base64,iVBORw0KGgo...",
  "paymentInfo": {
    "amount": 150000,
    "transactionId": "PAY1710123456789123",
    "method": "bank",
    "content": "DATSAN789123",
    "bookingCode": "BK1001"
  }
}
```

---

### 5.4 Kiểm tra trạng thái thanh toán 🔒
```
GET /api/payments/:id/status
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Lấy trạng thái thanh toán thành công",
  "payment": {
    "id": "payment_id",
    "amount": 150000,
    "method": "bank",
    "status": "pending",
    "transactionId": "PAY1710123456789123",
    "paidAt": null,
    "bookingCode": "BK1001",
    "bookingStatus": "pending"
  }
}
```

---

## 6. Wallet & Transactions

### 6.1 Lấy số dư ví 🔒
```
GET /api/wallet/balance
Authorization: Bearer <token>
```
> Tự tạo ví mới nếu user chưa có ví

**Response (200):**
```json
{
  "message": "Lấy số dư ví thành công",
  "wallet": { "id": "wallet_id", "balance": 500000, "points": 50, "tier": "member" }
}
```
> **tier** (theo tổng điểm thưởng `points`):
> - `member`: 0 <= points < 500
> - `silver`: 500 <= points < 1500
> - `gold`: 1500 <= points < 3000
> - `platinum`: points >= 3000

---

### 6.2 Nạp tiền vào ví 🔒
```
POST /api/wallet/top-up
Authorization: Bearer <token>
```
**Body:**
```json
{ "amount": 500000 }
```
> Tối thiểu: 10.000đ. Cộng 1 điểm thưởng cho mỗi 10.000đ nạp.

**Response (200):**
```json
{
  "message": "Nạp tiền thành công",
  "wallet": { "balance": 1000000, "points": 100, "tier": "silver", "earnedPoints": 50 }
}
```

---

### 6.3 Lịch sử giao dịch 🔒
```
GET /api/wallet/transactions?type=top_up&page=1&limit=20
Authorization: Bearer <token>
```
| Param | Mô tả |
|-------|--------|
| type | `top_up` / `payment` / `refund` (optional) |
| page, limit | Phân trang |

**Response (200):**
```json
{
  "message": "Lấy lịch sử giao dịch thành công",
  "transactions": [
    {
      "_id": "...",
      "type": "top_up",
      "amount": 500000,
      "description": "Nạp tiền vào ví +500.000đ",
      "status": "success",
      "relatedBooking": null,
      "createdAt": "2026-03-15T09:15:00.000Z"
    },
    {
      "_id": "...",
      "type": "payment",
      "amount": -150000,
      "description": "Thanh toán booking PAY1710...",
      "status": "success",
      "relatedBooking": { "bookingCode": "BK1001" },
      "createdAt": "2026-03-15T10:30:00.000Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 4, "totalPages": 1 }
}
```

---

## 7. Wishlist

### 7.1 Danh sách yêu thích 🔒
```
GET /api/wishlist
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Lấy danh sách yêu thích thành công",
  "courts": [
    {
      "_id": "665b...",
      "name": "SÂN BÓNG ĐÁ PM SPORT",
      "address": "104 Đ. Tân Sơn, P.15, Tân Bình",
      "images": ["https://..."],
      "logoUrl": "https://...",
      "openTime": "00:00",
      "closeTime": "24:00",
      "tags": ["Đơn ngày"],
      "ratingAvg": 4.2,
      "category": "Bóng đá"
    }
  ],
  "total": 1
}
```

---

### 7.2 Thêm vào yêu thích 🔒
```
POST /api/wishlist/:courtId
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Đã thêm \"SÂN BÓNG ĐÁ PM SPORT\" vào danh sách yêu thích",
  "courts": [ "..." ],
  "total": 2
}
```

---

### 7.3 Bỏ khỏi yêu thích 🔒
```
DELETE /api/wishlist/:courtId
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Đã bỏ sân khỏi danh sách yêu thích",
  "courts": [ "..." ],
  "total": 1
}
```

---

## 8. Notifications

### 8.1 Danh sách thông báo 🔒
```
GET /api/notifications?page=1&limit=20
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Lấy danh sách thông báo thành công",
  "notifications": [
    {
      "_id": "...",
      "title": "Đặt sân thành công",
      "content": "Sân PM PICKLEBALL của bạn đã được đặt vào lúc 17:30 ngày 2026-03-15. Mã vé: BK1001",
      "type": "booking",
      "isRead": false,
      "data": { "bookingId": "...", "bookingCode": "BK1001" },
      "createdAt": "2026-03-15T10:00:00.000Z"
    }
  ],
  "unreadCount": 2,
  "pagination": { "page": 1, "limit": 20, "total": 4, "totalPages": 1 }
}
```
> **type**: `booking` | `payment` | `promotion` | `system` | `reminder`

---

### 8.2 Đánh dấu đã đọc 1 thông báo 🔒
```
PUT /api/notifications/:id/read
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Đã đánh dấu đã đọc",
  "notification": { "_id": "...", "isRead": true }
}
```

---

### 8.3 Đánh dấu đã đọc tất cả 🔒
```
PUT /api/notifications/read-all
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Đã đánh dấu đọc tất cả thông báo",
  "modifiedCount": 3
}
```

---

## 9. Discounts

### 9.1 Voucher khả dụng 🔒
```
GET /api/discounts/my-vouchers
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Lấy danh sách voucher thành công",
  "vouchers": [
    {
      "_id": "...",
      "code": "WELCOME20",
      "description": "Giảm 20.000đ cho khách hàng lần đầu đặt sân trên ứng dụng.",
      "discountType": "fixed",
      "discountValue": 20000,
      "minOrderValue": 50000,
      "validFrom": "2026-01-01T00:00:00.000Z",
      "validTo": "2026-12-31T00:00:00.000Z",
      "usageLimit": 500,
      "usedCount": 10,
      "status": "active"
    },
    {
      "_id": "...",
      "code": "HAPPYHOUR",
      "description": "Giảm 10% khi đặt sân từ 10:00 - 14:00 ngày thường.",
      "discountType": "percent",
      "discountValue": 10,
      "maxDiscountAmount": 50000,
      "minOrderValue": 100000,
      "validTo": "2026-06-30T00:00:00.000Z",
      "status": "active"
    }
  ],
  "total": 3
}
```

---

### 9.2 Áp dụng mã giảm giá 🔒
```
POST /api/discounts/apply
Authorization: Bearer <token>
```
**Body:**
```json
{
  "code": "WELCOME20",
  "orderTotal": 150000
}
```
**Response (200):**
```json
{
  "message": "Áp dụng mã giảm giá thành công",
  "discount": {
    "id": "...",
    "code": "WELCOME20",
    "description": "Giảm 20.000đ cho khách hàng lần đầu",
    "discountType": "fixed",
    "discountValue": 20000,
    "discountAmount": 20000,
    "finalPrice": 130000
  }
}
```
**Các lỗi có thể:**
```
400: "Mã giảm giá đã hết hạn"
400: "Mã giảm giá đã hết lượt sử dụng"
400: "Đơn hàng tối thiểu 50.000đ để áp dụng mã này"
404: "Mã giảm giá không tồn tại hoặc đã bị vô hiệu"
```

---

## 10. Payment Methods

### 10.1 Danh sách phương thức thanh toán 🔒
```
GET /api/payment-methods
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "message": "Lấy danh sách phương thức thanh toán thành công",
  "paymentMethods": [
    {
      "_id": "...",
      "type": "visa",
      "name": "Visa •••• 1234",
      "accountNumber": "****1234",
      "bankName": "",
      "isDefault": true
    },
    {
      "_id": "...",
      "type": "momo",
      "name": "Ví MoMo",
      "accountNumber": "0909***456",
      "bankName": "",
      "isDefault": false
    }
  ],
  "total": 2
}
```

---

### 10.2 Thêm phương thức thanh toán 🔒
```
POST /api/payment-methods
Authorization: Bearer <token>
```
**Body:**
```json
{
  "type": "bank",
  "name": "Vietcombank",
  "accountNumber": "0123456789",
  "bankName": "Vietcombank",
  "isDefault": false
}
```
> **type**: `visa` | `momo` | `bank` | `vnpay`

**Response (201):**
```json
{
  "message": "Thêm phương thức thanh toán thành công",
  "paymentMethod": {
    "_id": "...",
    "type": "bank",
    "name": "Vietcombank",
    "accountNumber": "0123456789",
    "bankName": "Vietcombank",
    "isDefault": false
  }
}
```

---

### 10.3 Xóa phương thức thanh toán 🔒
```
DELETE /api/payment-methods/:id
Authorization: Bearer <token>
```
**Response (200):**
```json
{ "message": "Xóa phương thức thanh toán thành công" }
```

---

## Error Response Format

Tất cả API trả lỗi theo format thống nhất:

| Status | Ý nghĩa |
|--------|----------|
| `400` | Bad Request — Dữ liệu không hợp lệ |
| `401` | Unauthorized — Chưa đăng nhập / thiếu token |
| `403` | Forbidden — Không có quyền |
| `404` | Not Found — Không tìm thấy |
| `500` | Server Error — Lỗi server |

```json
{
  "message": "Mô tả lỗi bằng tiếng Việt",
  "error": "Chi tiết lỗi kỹ thuật (chỉ có ở 500)"
}
```

---

## Seed Data (Dữ liệu mẫu)

```bash
cd backend_server
node api/seedData.js
```
Sẽ tạo: 5 sân + 44 sân con + 5 mã giảm giá

---

## Tổng kết — 39 API Endpoints

| # | Method | Endpoint | Auth | Mô tả |
|---|--------|----------|------|--------|
| 1 | POST | `/api/auth/register` | ❌ | Đăng ký |
| 2 | POST | `/api/auth/login` | ❌ | Đăng nhập |
| 3 | POST | `/api/auth/verify-email` | ❌ | Xác thực email |
| 4 | POST | `/api/auth/resend-code` | ❌ | Gửi lại mã |
| 5 | POST | `/api/auth/forgot-password` | ❌ | Quên mật khẩu |
| 6 | POST | `/api/auth/reset-password` | ❌ | Đặt lại mật khẩu |
| 7 | GET | `/api/auth/me` | 🔒 | Thông tin user |
| 8 | POST | `/api/auth/logout` | 🔒 | Đăng xuất |
| 9 | PUT | `/api/users/profile` | 🔒 | Cập nhật thông tin |
| 10 | POST | `/api/users/avatar` | 🔒 | Upload avatar |
| 11 | GET | `/api/users/wallet` | 🔒 | Thông tin ví |
| 12 | GET | `/api/courts` | ❌ | Danh sách sân |
| 13 | GET | `/api/courts/search` | ❌ | Tìm kiếm sân |
| 14 | GET | `/api/courts/nearby` | ❌ | Sân gần đây |
| 15 | GET | `/api/courts/:id` | ❌ | Chi tiết sân |
| 16 | GET | `/api/courts/:id/sub-courts` | ❌ | Sân con |
| 17 | GET | `/api/courts/:id/time-slots` | ❌ | Slot giờ |
| 18 | POST | `/api/bookings` | 🔒 | Tạo booking |
| 19 | GET | `/api/bookings` | 🔒 | Danh sách vé |
| 20 | GET | `/api/bookings/:id` | 🔒 | Chi tiết booking |
| 21 | PUT | `/api/bookings/:id/cancel` | 🔒 | Hủy booking |
| 22 | POST | `/api/payments` | 🔒 | Tạo thanh toán |
| 23 | PUT | `/api/payments/:id/confirm` | 🔒 | Xác nhận TT |
| 24 | GET | `/api/payments/:id/qr-code` | 🔒 | Mã QR |
| 25 | GET | `/api/payments/:id/status` | 🔒 | Trạng thái TT |
| 26 | GET | `/api/wallet/balance` | 🔒 | Số dư ví |
| 27 | POST | `/api/wallet/top-up` | 🔒 | Nạp tiền |
| 28 | GET | `/api/wallet/transactions` | 🔒 | Lịch sử GD |
| 29 | GET | `/api/wishlist` | 🔒 | DS yêu thích |
| 30 | POST | `/api/wishlist/:courtId` | 🔒 | Thêm yêu thích |
| 31 | DELETE | `/api/wishlist/:courtId` | 🔒 | Bỏ yêu thích |
| 32 | GET | `/api/notifications` | 🔒 | DS thông báo |
| 33 | PUT | `/api/notifications/:id/read` | 🔒 | Đọc 1 TB |
| 34 | PUT | `/api/notifications/read-all` | 🔒 | Đọc tất cả |
| 35 | GET | `/api/discounts/my-vouchers` | 🔒 | Voucher |
| 36 | POST | `/api/discounts/apply` | 🔒 | Áp mã giảm giá |
| 37 | GET | `/api/payment-methods` | 🔒 | DS PTTT |
| 38 | POST | `/api/payment-methods` | 🔒 | Thêm PTTT |
| 39 | DELETE | `/api/payment-methods/:id` | 🔒 | Xóa PTTT |

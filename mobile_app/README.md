# booking

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Booking App (Flutter)

## ⚙️ Thiết lập môi trường (Bắt buộc sau khi clone)

### 1. Tạo file `.env` cho Mobile App

```bash
cd mobile_app
cp .env.example .env
```

Sau đó mở `.env` và điền IP máy đang chạy backend:

```env
API_BASE_URL=http://<IP_CUA_BAN>:5000/api
```

> 💡 Lấy IP: **macOS** → `ipconfig getifaddr en0` | **Windows** → `ipconfig` → xem `IPv4 Address`

### 2. Tạo file `.env` cho Backend Server

```bash
cd backend_server
cp .env.example .env
```

Điền thông tin MongoDB, JWT, Gmail vào file `.env`.

### 3. Chạy dự án

```bash
# Terminal 1 - Backend
cd backend_server
npm install
node server.js

# Terminal 2 - Mobile App
cd mobile_app
flutter pub get
flutter run
```

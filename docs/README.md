# 📚 TOEIC Practice App - Documentation

Tài liệu hướng dẫn cho dự án TOEIC Practice App (Flutter + Express Backend)

---

## 📖 Danh sách tài liệu

### 🏗️ Architecture & Structure
- **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** - Cấu trúc dự án cuối cùng (Clean & Ready)
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Giải thích chi tiết về Feature-based Architecture
- **[REFACTORING_COMPLETE.md](./REFACTORING_COMPLETE.md)** - Tóm tắt quá trình refactoring

### 🔌 API Integration
- **[API_INTEGRATION.md](./API_INTEGRATION.md)** - Hướng dẫn tích hợp API với MVVM pattern

---

## 🚀 Quick Start

### 1. Đọc cấu trúc dự án
Bắt đầu với [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) để hiểu cấu trúc tổng quan.

### 2. Hiểu kiến trúc
Đọc [ARCHITECTURE.md](./ARCHITECTURE.md) để nắm rõ Feature-based Architecture.

### 3. Tích hợp API
Xem [API_INTEGRATION.md](./API_INTEGRATION.md) để biết cách kết nối với backend.

---

## 📂 Cấu trúc dự án tóm tắt

```
toeic_practice_app/
├── lib/
│   ├── core/              # Shared/Common
│   ├── features/          # Feature modules
│   │   ├── auth/         # Authentication
│   │   ├── home/         # Home screen
│   │   ├── practice/     # Practice (TODO)
│   │   ├── progress/     # Progress (TODO)
│   │   └── profile/      # Profile (TODO)
│   └── main.dart
│
├── docs/                  # 📚 Documentation
│   ├── README.md         # This file
│   ├── PROJECT_STRUCTURE.md
│   ├── ARCHITECTURE.md
│   ├── REFACTORING_COMPLETE.md
│   └── API_INTEGRATION.md
│
└── README.md             # Main README
```

---

## 🎯 Nguyên tắc

### Feature-based Architecture
- Mỗi feature là một module độc lập
- Cấu trúc: `models/`, `services/`, `viewmodels/`, `views/`
- Shared code nằm trong `core/`

### MVVM Pattern
- **Model**: Data structures
- **View**: UI components
- **ViewModel**: Business logic + State management

### API Service Layer
- `core/services/api_service.dart` - Base HTTP service
- `features/*/services/*_api_service.dart` - Feature-specific API calls

---

## 📞 Backend API

Backend chạy tại: `http://localhost:3000/api`

**Endpoints:**
- `POST /api/auth/login` - Đăng nhập
- `GET /api/auth/me` - Lấy thông tin user
- `GET /api/health` - Health check

**Test accounts:**
- Email: `student@toeic.com` | Password: `123456`
- Email: `hocvien@test.com` | Password: `password`

---

## 🔜 Roadmap

- [x] Auth module (Login)
- [x] Home module
- [ ] Practice module (Luyện tập TOEIC)
- [ ] Progress module (Theo dõi tiến độ)
- [ ] Profile module (Hồ sơ người dùng)
- [ ] Database integration
- [ ] JWT authentication

---

## 📝 Contributing

Khi thêm feature mới:
1. Tạo thư mục trong `lib/features/`
2. Tuân theo cấu trúc: `models/`, `services/`, `viewmodels/`, `views/`
3. Update documentation

---

**Made with ❤️ for TOEIC learners**

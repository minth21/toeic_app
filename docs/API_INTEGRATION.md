# 🔌 API Integration - Flutter MVVM

## 📂 Cấu trúc API Service Layer

```
lib/
├── services/                    ⭐ API Service Layer
│   ├── api_config.dart          # Cấu hình API (base URL, endpoints)
│   ├── api_service.dart         # Base HTTP service (GET, POST, PUT, DELETE)
│   └── auth_api_service.dart    # Auth-specific API calls
│
├── viewmodels/
│   └── auth_viewmodel.dart      # Sử dụng AuthApiService
│
├── models/
│   └── user_model.dart          # Data model
│
└── views/
    └── screens/
        ├── login_screen.dart
        └── home_screen.dart
```

---

## 🔄 Luồng hoạt động MVVM + API

```
📱 View (Login Screen)
    ↓ User nhập email/password
🎮 ViewModel (AuthViewModel)
    ↓ Gọi login()
🌐 API Service (AuthApiService)
    ↓ HTTP POST /api/auth/login
🔌 Backend API (Express)
    ↓ Response: {success, user, token}
🌐 API Service
    ↓ Parse response
🎮 ViewModel
    ↓ Update state (currentUser, token)
📱 View
    ↓ Navigate to Home Screen
```

---

## 📝 Các file đã tạo

### 1. **api_config.dart** - Cấu hình API
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  // ...
}
```

### 2. **api_service.dart** - Base HTTP Service
```dart
class ApiService {
  Future<Map<String, dynamic>> get(String endpoint, {...});
  Future<Map<String, dynamic>> post(String endpoint, {...});
  Future<Map<String, dynamic>> put(String endpoint, {...});
  Future<Map<String, dynamic>> delete(String endpoint, {...});
}
```

### 3. **auth_api_service.dart** - Auth API Service
```dart
class AuthApiService {
  Future<Map<String, dynamic>> login({email, password});
  Future<Map<String, dynamic>> getCurrentUser(String token);
  Future<Map<String, dynamic>> healthCheck();
}
```

### 4. **auth_viewmodel.dart** - Updated ViewModel
- ✅ Sử dụng `AuthApiService` thay vì mock data
- ✅ Xử lý response từ backend
- ✅ Lưu token
- ✅ Error handling

---

## 🧪 Test kết nối

### Bước 1: Đảm bảo backend đang chạy
```bash
cd toeic_practice_backend
npm run dev
```

Backend phải chạy tại: `http://localhost:3000`

### Bước 2: Chạy Flutter app
```bash
cd toeic_practice_app
flutter run
```

### Bước 3: Test login
- Email: `student@toeic.com`
- Password: `123456`

---

## 🔍 Debug

### Nếu không kết nối được:

#### 1. Kiểm tra backend đang chạy
```bash
curl http://localhost:3000/api/health
```

#### 2. Kiểm tra Flutter có thể gọi localhost
- **Android Emulator**: Dùng `http://10.0.2.2:3000/api` thay vì `localhost`
- **iOS Simulator**: Dùng `http://localhost:3000/api`
- **Physical Device**: Dùng IP máy tính (vd: `http://192.168.1.100:3000/api`)

#### 3. Update api_config.dart nếu cần
```dart
// Cho Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// Cho iOS Simulator
static const String baseUrl = 'http://localhost:3000/api';

// Cho Physical Device
static const String baseUrl = 'http://192.168.1.100:3000/api';
```

---

## ✅ Checklist

- [x] Tạo `api_config.dart` - Cấu hình API
- [x] Tạo `api_service.dart` - Base HTTP service
- [x] Tạo `auth_api_service.dart` - Auth API service
- [x] Update `auth_viewmodel.dart` - Sử dụng API thật
- [x] Thêm `http` package vào `pubspec.yaml`
- [ ] Test kết nối với backend
- [ ] Update base URL cho emulator/device

---

## 🔜 Bước tiếp theo

1. **Test API connection** - Chạy app và test login
2. **Lưu token** - Implement SharedPreferences để lưu token
3. **Auto login** - Check token khi mở app
4. **Thêm API services khác** - Tests, Progress, etc.

---

**Made with ❤️ for TOEIC learners**

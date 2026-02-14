# 🎯 TOEIC-TEST App - MVVM Pattern

## ✅ Đã Hoàn Thành

### 1. Cấu trúc MVVM
```
lib/
├── constants/
│   └── app_constants.dart       # Colors, Strings
├── models/
│   ├── user_model.dart          # User data model
│   ├── question_model.dart      # Question model
│   └── test_model.dart          # Test model
├── viewmodels/
│   └── auth_viewmodel.dart      # Authentication logic
├── views/
│   └── screens/
│       ├── login_screen.dart    # Màn hình đăng nhập
│       └── home_screen.dart     # Màn hình home
└── main.dart                    # Entry point với Provider
```

### 2. Tính Năng Đã Implement
- ✅ **Login Screen** với form validation
- ✅ **Home Screen** hiển thị thông tin user
- ✅ **MVVM Pattern** với Provider
- ✅ **Mock Data** - dữ liệu cứng để test
- ✅ **Navigation** - chuyển màn hình sau khi login
- ✅ **Logout** - quay về màn hình login

## 🚀 Cách Chạy App

### Bước 1: Cài đặt dependencies
```bash
cd toeic_practice_app
flutter pub get
```

### Bước 2: Chọn device

#### Option A: Android Emulator
1. Mở Android Studio
2. Tools → Device Manager
3. Tạo/Chạy một emulator
4. Chạy: `flutter run`

#### Option B: Chrome (Web)
```bash
flutter run -d chrome
```

#### Option C: Windows Desktop
```bash
flutter run -d windows
```

### Bước 3: Test đăng nhập

Sử dụng một trong các tài khoản demo:

**Tài khoản 1:**
- Email: `admin@toeic.com`
- Password: `123456`

**Tài khoản 2:**
- Email: `user@test.com`
- Password: `password`

## 📱 Luồng Hoạt Động

1. **Màn hình Login**
   - Nhập email và password
   - Validation tự động
   - Hiển thị loading khi đang xử lý
   - Hiển thị lỗi nếu sai thông tin

2. **Sau khi đăng nhập thành công**
   - Chuyển sang màn hình Home
   - Hiển thị thông tin user
   - Hiển thị thống kê (số bài thi, điểm TB)
   - Các action buttons (sẽ phát triển sau)

3. **Logout**
   - Click icon logout trên AppBar
   - Confirm dialog
   - Quay về màn hình Login

## 🎨 UI Features

### Login Screen
- ✅ Modern design với Google Fonts
- ✅ Form validation
- ✅ Show/Hide password
- ✅ Loading indicator
- ✅ Error messages
- ✅ Demo credentials display

### Home Screen
- ✅ Welcome card với gradient
- ✅ Stats cards (Bài thi, Điểm TB)
- ✅ Action buttons với icons
- ✅ Logout functionality
- ✅ Coming soon dialogs

## 🔧 Kiến Trúc MVVM

### Model
```dart
// lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String name;
  // ... other fields
}
```

### ViewModel
```dart
// lib/viewmodels/auth_viewmodel.dart
class AuthViewModel extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  
  Future<bool> login(String email, String password) async {
    // Business logic here
    notifyListeners();
  }
}
```

### View
```dart
// lib/views/screens/login_screen.dart
Consumer<AuthViewModel>(
  builder: (context, authViewModel, child) {
    return ElevatedButton(
      onPressed: authViewModel.isLoading ? null : _handleLogin,
      child: Text('Login'),
    );
  },
)
```

## 📦 Dependencies Đã Sử Dụng

```yaml
dependencies:
  provider: ^6.1.1              # State management
  google_fonts: ^6.1.0          # Custom fonts
  shared_preferences: ^2.2.2    # Local storage
  intl: ^0.19.0                 # Internationalization
```

## 🎯 Các Bước Tiếp Theo

### Phase 1: Hoàn thiện Authentication
- [ ] Thêm Register Screen
- [ ] Thêm Forgot Password Screen
- [ ] Lưu login state với SharedPreferences
- [ ] Auto-login nếu đã đăng nhập

### Phase 2: Practice Features
- [ ] Test List Screen
- [ ] Test Detail Screen
- [ ] Test Taking Screen
- [ ] Result Screen

### Phase 3: Backend Integration
- [ ] Thay mock data bằng API calls
- [ ] Implement real authentication
- [ ] Sync data với server

## 💡 Tips

### Hot Reload
Sau khi chạy app, bạn có thể:
- Nhấn `r` để hot reload (reload UI)
- Nhấn `R` để hot restart (restart app)

### Debug
- Sử dụng `print()` để debug
- Hoặc dùng debugger trong VS Code/Android Studio

### Customize
- Thay đổi colors trong `lib/constants/app_constants.dart`
- Thay đổi strings/messages trong cùng file
- Thêm mock users trong `auth_viewmodel.dart`

## 📸 Screenshots

### Login Screen
- Form đăng nhập đẹp mắt
- Validation realtime
- Demo credentials hiển thị sẵn

### Home Screen
- Welcome card với tên user
- Stats cards
- Action buttons cho các tính năng

## ❓ Troubleshooting

### Lỗi: No devices found
```bash
# Kiểm tra devices
flutter devices

# Chạy trên Chrome
flutter run -d chrome

# Chạy trên Windows
flutter run -d windows
```

### Lỗi: Package not found
```bash
flutter clean
flutter pub get
```

### Lỗi: Build failed
```bash
flutter clean
flutter pub get
flutter run
```

## 📝 Notes

- App sử dụng **mock data** - không cần backend
- Tất cả dữ liệu đều hardcoded trong code
- Login chỉ check email/password trong memory
- Chưa có persistent storage (logout sẽ mất data)

---

**Tạo bởi**: MVVM Pattern với Provider
**Framework**: Flutter
**State Management**: Provider (MVVM)

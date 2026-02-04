# 🏗️ Flutter App - Feature-based Architecture

## 📂 Cấu trúc dự án mới (Clean & Scalable)

```
lib/
├── core/                          🔧 CORE - Shared/Common
│   ├── config/
│   │   └── api_config.dart        # API endpoints, base URL
│   ├── services/
│   │   └── api_service.dart       # Base HTTP service (GET, POST, PUT, DELETE)
│   ├── utils/
│   │   ├── constants.dart         # App constants, strings
│   │   └── validators.dart        # Form validators
│   └── widgets/                   # Shared widgets (sẽ thêm sau)
│
├── features/                      📦 FEATURES - Chia theo module
│   │
│   ├── auth/                      🔐 AUTH MODULE
│   │   ├── models/
│   │   │   └── user_model.dart
│   │   ├── services/
│   │   │   └── auth_api_service.dart
│   │   ├── viewmodels/
│   │   │   └── auth_viewmodel.dart
│   │   └── views/
│   │       └── login_screen.dart
│   │
│   ├── home/                      🏠 HOME MODULE
│   │   ├── viewmodels/
│   │   │   └── home_viewmodel.dart (sẽ tạo)
│   │   └── views/
│   │       └── home_screen.dart
│   │
│   ├── practice/                  📝 PRACTICE MODULE (sẽ tạo)
│   │   ├── models/
│   │   ├── services/
│   │   ├── viewmodels/
│   │   └── views/
│   │
│   ├── progress/                  📊 PROGRESS MODULE (sẽ tạo)
│   │   ├── models/
│   │   ├── services/
│   │   ├── viewmodels/
│   │   └── views/
│   │
│   └── profile/                   👤 PROFILE MODULE (sẽ tạo)
│       ├── models/
│       ├── services/
│       ├── viewmodels/
│       └── views/
│
├── constants/                     ⚠️ DEPRECATED - Di chuyển sang core/utils
│   └── app_constants.dart
│
└── main.dart                      🚀 Entry point
```

---

## 🎯 Nguyên tắc tổ chức

### 1. **Core** - Dùng chung cho toàn app
- **config**: Cấu hình API, environment
- **services**: Base services (HTTP, Storage, etc.)
- **utils**: Utilities, helpers, validators
- **widgets**: Shared UI components

### 2. **Features** - Mỗi feature độc lập
Mỗi feature có cấu trúc riêng:
```
feature_name/
├── models/       # Data models
├── services/     # API services
├── viewmodels/   # Business logic + State
└── views/        # UI screens
```

---

## ✅ Đã hoàn thành

### Core Layer
- [x] `core/config/api_config.dart` - API configuration
- [x] `core/services/api_service.dart` - Base HTTP service
- [x] `core/utils/constants.dart` - App constants
- [x] `core/utils/validators.dart` - Form validators

### Auth Feature
- [x] `features/auth/models/user_model.dart`
- [x] `features/auth/services/auth_api_service.dart`
- [x] `features/auth/viewmodels/auth_viewmodel.dart`
- [x] `features/auth/views/login_screen.dart`

### Home Feature
- [x] `features/home/views/home_screen.dart` (cần update imports)

---

## 🔜 Cần làm tiếp

1. **Update main.dart** - Import từ features mới
2. **Update home_screen.dart** - Fix imports
3. **Xóa old structure** - Xóa lib/models, lib/services, lib/viewmodels, lib/views cũ
4. **Tạo features mới**:
   - Practice (Luyện tập)
   - Progress (Tiến độ)
   - Profile (Hồ sơ)

---

## 💡 Ưu điểm

✅ **Tách biệt rõ ràng** - Mỗi feature độc lập  
✅ **Dễ bảo trì** - Sửa auth không ảnh hưởng practice  
✅ **Dễ mở rộng** - Thêm feature mới không conflict  
✅ **Team-friendly** - Nhiều người làm cùng lúc  
✅ **Scalable** - Dự án lớn vẫn clean  

---

## 📝 Import Guidelines

### Từ Core
```dart
import 'package:toeic_practice_app/core/config/api_config.dart';
import 'package:toeic_practice_app/core/services/api_service.dart';
import 'package:toeic_practice_app/core/utils/constants.dart';
import 'package:toeic_practice_app/core/utils/validators.dart';
```

### Từ Features
```dart
// Auth
import 'package:toeic_practice_app/features/auth/models/user_model.dart';
import 'package:toeic_practice_app/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:toeic_practice_app/features/auth/views/login_screen.dart';

// Home
import 'package:toeic_practice_app/features/home/views/home_screen.dart';
```

---

**Made with ❤️ for Clean Architecture**

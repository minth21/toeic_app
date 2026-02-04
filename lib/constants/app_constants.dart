import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // Android emulator localhost
}

class AppColors {
  // Primary Colors - Xanh nhạt hiện đại (Modern Light Blue)
  static const Color primary = Color(
    0xFF42A5F5,
  ); // Light Blue (Material Blue 400)
  static const Color primaryDark = Color(0xFF1976D2); // Medium Blue
  static const Color primaryLight = Color(0xFF90CAF9); // Very Light Blue

  // Secondary/Accent Colors - Cam nhấn
  static const Color accent = Color(0xFFFF6F00); // Deep Orange
  static const Color accentDark = Color(0xFFC43E00);
  static const Color accentLight = Color(0xFFFF9E40);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA); // Light gray
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF2E7D32); // Dark Green
  static const Color error = Color(0xFFC62828); // Dark Red
  static const Color warning = Color(0xFFF57C00); // Orange
  static const Color info = Color(0xFF1976D2); // Blue

  // Other
  static const Color divider = Color(0xFFE0E0E0);
  static const Color disabled = Color(0xFFBDBDBD);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF42A5F5), Color(0xFF1976D2)], // Light to Medium Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppStrings {
  // App
  static const String appName = 'TOEIC Practice';

  // Auth
  static const String login = 'Đăng nhập';
  static const String register = 'Đăng ký';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String fullName = 'Họ và tên';
  static const String confirmPassword = 'Xác nhận mật khẩu';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String dontHaveAccount = 'Chưa có tài khoản?';
  static const String alreadyHaveAccount = 'Đã có tài khoản?';
  static const String loginSuccess = 'Đăng nhập thành công!';
  static const String loginFailed = 'Email hoặc mật khẩu không đúng';
  static const String registerSuccess = 'Đăng ký thành công!';
  static const String registerFailed = 'Đăng ký thất bại. Vui lòng thử lại';
  static const String createAccount = 'Tạo tài khoản mới';

  // Validation
  static const String emailRequired = 'Vui lòng nhập email';
  static const String emailInvalid = 'Email không hợp lệ';
  static const String passwordRequired = 'Vui lòng nhập mật khẩu';
  static const String passwordTooShort = 'Mật khẩu phải có ít nhất 6 ký tự';
  static const String fullNameRequired = 'Vui lòng nhập họ và tên';
  static const String confirmPasswordRequired = 'Vui lòng xác nhận mật khẩu';
  static const String passwordNotMatch = 'Mật khẩu không khớp';

  // Home
  static const String welcome = 'Chào mừng';
  static const String startPractice = 'Bắt đầu luyện tập';
  static const String myProgress = 'Tiến độ của tôi';
  static const String logout = 'Đăng xuất';
}

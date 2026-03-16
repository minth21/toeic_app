import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // Android emulator localhost
}

class AppColors {
  // Primary Colors - Modern Blue Theme
  static const Color primary = Color(0xFF1E40AF); // Deep Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color background = Color(0xFFF1F5F9); // Light Gray Background
  static const Color surface = Color(0xFFFFFFFF);

  // Pastel Shades (Maintained for compatibility, updated for new theme)
  static const Color pastelBlue = Color(0xFFE0E7FF); // Indigo 100
  static const Color pastelBlueLight = Color(0xFFEEF2FF); // Indigo 50
  static const Color pastelBlueDark = Color(0xFFC7D2FE); // Indigo 200

  // Secondary/Accent Colors
  static const Color accent = Color(0xFFF59E0B); // Amber 500
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFBBF24);

  // Background Colors (Updated)
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Other
  static const Color divider = Color(0xFFE2E8F0); // Slate 200
  static const Color disabled = Color(0xFFCBD5E1); // Slate 300

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Slate 100
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkCardBackground = Color(0xFF1E293B);
}

class AppShadows {
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get deepShadow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];
}

class AppStrings {
  // App
  static const String appName = 'TOEIC - TEST';

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

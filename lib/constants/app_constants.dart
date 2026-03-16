import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // Android emulator localhost
}

class AppColors {
  // Primary Colors - Premium Indigo-Purple Theme (Synchronized with Admin)
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color secondary = Color(0xFF8B5CF6); // Violet 500
  
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);

  // Premium Palette
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color purple50 = Color(0xFFF5F3FF);
  static const Color purple100 = Color(0xFFEDE9FE);

  // Status Colors (Emerald & Amber)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Text Colors (Slate)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textHint = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // UI Elements
  static const Color divider = Color(0xFFE2E8F0); // Slate 200
  static const Color border = Color(0xFFCBD5E1); 

  // Gradient Colors (Matching Admin Panels)
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
}

class AppShadows {
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: const Color(0xFF6366F1).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
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

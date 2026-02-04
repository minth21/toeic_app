class AppConstants {
  // App Info
  static const String appName = 'TOEIC Practice';
  static const String appVersion = '1.0.0';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
}

class AppStrings {
  // App
  static const String appName = 'TOEIC Practice';

  // Auth
  static const String login = 'Đăng nhập';
  static const String logout = 'Đăng xuất';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String emailRequired = 'Vui lòng nhập email';
  static const String emailInvalid = 'Email không hợp lệ';
  static const String passwordRequired = 'Vui lòng nhập mật khẩu';
  static const String passwordTooShort = 'Mật khẩu phải có ít nhất 6 ký tự';
  static const String loginFailed = 'Đăng nhập thất bại';
  static const String welcome = 'Chào mừng';

  // Home
  static const String startPractice = 'Bắt đầu luyện tập';
  static const String myProgress = 'Tiến độ của tôi';

  // Common
  static const String cancel = 'Hủy';
  static const String confirm = 'Xác nhận';
  static const String save = 'Lưu';
  static const String delete = 'Xóa';
  static const String edit = 'Sửa';
  static const String loading = 'Đang tải...';
  static const String error = 'Lỗi';
  static const String success = 'Thành công';
}

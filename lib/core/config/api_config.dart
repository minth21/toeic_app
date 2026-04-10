class ApiConfig {
  // Base URL của backend
  // Dùng 10.0.2.2 cho Android Emulator (thay vì localhost)
  // Dùng localhost cho iOS Simulator
  // Dùng IP máy tính cho Physical Device
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Auth Endpoints (đang dùng)
  static const String authLogin = '/auth/login';
  static const String authGoogle = '/auth/google';
  static const String authRegister = '/auth/register';
  static const String authMe = '/auth/me';
  static const String usersMe = '/users/me';
  static const String userAvatar = '/users/avatar';
  static const String dashboardStudent = '/dashboard/student';

  // Password Reset Endpoints
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authVerifyResetCode = '/auth/verify-reset-code';
  static const String authResetPassword = '/auth/reset-password';
  static const String authChangePassword = '/auth/change-password';
  static const String authChangeFirstPassword = '/auth/change-first-password';
  static const String aiTimeline = '/ai/timeline';
  static const String flashcards = '/flashcards';
  static const String feedbacks = '/feedbacks';
  static const String classMaterials = '/classes';

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> headersWithAuth(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}

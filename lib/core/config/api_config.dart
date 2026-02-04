class ApiConfig {
  // Base URL của backend
  // Dùng 10.0.2.2 cho Android Emulator (thay vì localhost)
  // Dùng localhost cho iOS Simulator
  // Dùng IP máy tính cho Physical Device
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Auth Endpoints (đang dùng)
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authMe = '/auth/me';

  // Password Reset Endpoints
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authVerifyResetCode = '/auth/verify-reset-code';
  static const String authResetPassword = '/auth/reset-password';

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

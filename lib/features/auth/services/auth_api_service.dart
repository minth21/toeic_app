import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';
import 'package:intl/intl.dart';

import 'package:google_sign_in/google_sign_in.dart';

/// Auth API Service - Xử lý tất cả API calls liên quan đến authentication
class AuthApiService {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '112210310564-j3r1bsrtohpb30d53vfao2kp7knchfrl.apps.googleusercontent.com',
  );

  /// Login với email và password
  /// Returns: {success, message, user, token}
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.authLogin,
        body: {'email': email, 'password': password},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Google Login Flow
  /// 1. Sign In with Google SDK -> Get ID Token
  /// 2. Send ID Token to Backend -> Get User & JWT
  Future<Map<String, dynamic>> googleLogin() async {
    try {
      // 1. Sign In with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled
        return {'success': false, 'message': 'Đăng nhập Google bị hủy'};
      }

      // 2. Get ID Token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return {'success': false, 'message': 'Không lấy được Google ID Token'};
      }

      // 3. Send to Backend
      final response = await _apiService.post(
        ApiConfig.authGoogle,
        body: {'idToken': idToken},
      );

      return response;
    } catch (e) {
      debugPrint('Google Login API Error: $e');
      return {'success': false, 'message': 'Lỗi đăng nhập Google: $e'};
    }
  }

  /// Sign out Google
  Future<void> googleSignOut() async {
    await _googleSignIn.signOut();
  }

  /// Register new user với name, email và password
  /// Returns: {success, message, user, token}
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
      };

      // Add optional fields if provided
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }
      if (dateOfBirth != null) {
        body['dateOfBirth'] = DateFormat('yyyy-MM-dd').format(dateOfBirth);
      }
      if (gender != null) {
        body['gender'] = gender;
      }

      final response = await _apiService.post(
        ApiConfig.authRegister,
        body: body,
        headers: ApiConfig
            .headers, // Remove specific header call if not needed or stick to default
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user info (cần token)
  /// Returns: {success, data: {user}}
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await _apiService.get(
        ApiConfig.authMe,
        headers: ApiConfig.headersWithAuth(token),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  /// Returns: {success, message, user}
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? token,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (dateOfBirth != null) {
        body['dateOfBirth'] = DateFormat('yyyy-MM-dd').format(dateOfBirth);
      }
      if (gender != null) body['gender'] = gender;

      final response = await _apiService.patch(
        ApiConfig.usersMe,
        body: body,
        headers: ApiConfig.headersWithAuth(token ?? ''),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Parse user from API response
  UserModel? parseUser(Map<String, dynamic>? userData) {
    if (userData == null) return null;

    try {
      return UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('Error parsing user: $e');
      return null;
    }
  }

  // ============================================
  // PASSWORD RESET METHODS
  // ============================================

  /// Request password reset - Gửi OTP qua email
  /// Returns: {success, message}
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.authForgotPassword,
        body: {'email': email},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify reset OTP code (optional)
  /// Returns: {success, message}
  Future<Map<String, dynamic>> verifyResetCode({required String code}) async {
    try {
      final response = await _apiService.post(
        ApiConfig.authVerifyResetCode,
        body: {'code': code},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password with OTP code
  /// Returns: {success, message}
  Future<Map<String, dynamic>> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.authResetPassword,
        body: {'code': code, 'newPassword': newPassword},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Change password (cần token)
  /// Returns: {success, message}
  Future<Map<String, dynamic>> changePassword({
    String? oldPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{'newPassword': newPassword};
      if (oldPassword != null) {
        body['oldPassword'] = oldPassword;
      }

      final response = await _apiService.patch(
        ApiConfig.authChangePassword,
        body: body,
        headers: ApiConfig.headersWithAuth(token),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }
}

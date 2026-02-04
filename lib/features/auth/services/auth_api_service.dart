import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';

/// Auth API Service - Xử lý tất cả API calls liên quan đến authentication
class AuthApiService {
  final ApiService _apiService = ApiService();

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

  /// Register new user với name, email và password
  /// Returns: {success, message, user, token}
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    int? toeicLevel,
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
        body['dateOfBirth'] = dateOfBirth.toIso8601String();
      }
      if (gender != null) {
        body['gender'] = gender;
      }
      if (toeicLevel != null) {
        body['toeicLevel'] = toeicLevel;
      }

      final response = await _apiService.post(
        ApiConfig.authRegister,
        body: body,
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
}

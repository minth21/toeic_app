import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';
import 'package:intl/intl.dart';

class AuthApiService {
  final ApiService _apiService = ApiService();

  /// Login với username và password
  /// Returns: {success, message, user, token}
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.authLogin,
        body: {'username': username, 'password': password},
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
    String? avatarUrl,
    int? targetScore,
    String? token,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (dateOfBirth != null) {
        body['dateOfBirth'] = DateFormat('yyyy-MM-dd').format(dateOfBirth);
      }
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
      if (targetScore != null) body['targetScore'] = targetScore;

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
  
  /// Change password lần đầu login (cần token)
  Future<Map<String, dynamic>> changeFirstPassword({
    required String newPassword,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{'newPassword': newPassword};

      final response = await _apiService.post(
        ApiConfig.authChangeFirstPassword,
        body: body,
        headers: ApiConfig.headersWithAuth(token),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload user avatar
  /// POST /api/users/avatar
  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    try {
      final storageService = StorageService();
      final token = await storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      return await _apiService.uploadFile(
        ApiConfig.userAvatar,
        filePath,
        field: 'image',
        headers: ApiConfig.headersWithAuth(token),
      );
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthApiService _authApiService = AuthApiService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null && _token != null;

  /// Login với API thật
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi API login
      final response = await _authApiService.login(
        email: email,
        password: password,
      );

      // Kiểm tra response
      if (response['success'] == true) {
        // Parse user từ response
        final userData = response['user'];
        if (userData != null) {
          _currentUser = _authApiService.parseUser(userData);
          _token = response['token'];

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Không nhận được thông tin người dùng';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = response['message'] ?? 'Đăng nhập thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user with API
  Future<bool> register(
    String name,
    String email,
    String password, {
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    int? toeicLevel,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi API register
      final response = await _authApiService.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        toeicLevel: toeicLevel,
      );

      // Kiểm tra response
      if (response['success'] == true) {
        // Parse user từ response
        final userData = response['user'];
        if (userData != null) {
          _currentUser = _authApiService.parseUser(userData);
          _token = response['token'];

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Không nhận được thông tin người dùng';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = response['message'] ?? 'Đăng ký thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Lấy thông tin user hiện tại (dùng token)
  Future<bool> getCurrentUser() async {
    if (_token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authApiService.getCurrentUser(_token!);

      if (response['success'] == true) {
        final userData = response['data']?['user'];
        if (userData != null) {
          _currentUser = _authApiService.parseUser(userData);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi khi lấy thông tin user: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh current user data (sau khi upload avatar, etc.)
  Future<bool> refreshCurrentUser() async {
    return await getCurrentUser();
  }

  /// Logout
  void logout() {
    _currentUser = null;
    _token = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

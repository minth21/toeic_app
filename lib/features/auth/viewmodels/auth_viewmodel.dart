import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../../../core/services/storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthApiService _authApiService = AuthApiService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null && _token != null;

  /// Load User & Token from Storage on Init
  Future<void> loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token != null) {
        // Verify token & get user info
        final response = await _authApiService.getCurrentUser(token);
        if (response['success'] == true) {
          final userData = response['data']?['user'];
          if (userData != null) {
            final user = _authApiService.parseUser(userData);
            
            if (user == null) {
              _errorMessage = 'Lỗi dữ liệu người dùng';
              _isLoading = false;
              notifyListeners();
              return;
            }

            // ROLE CHECK: Only Admin & Student can access Mobile
            if (!user.canAccessMobileApp) {
              _errorMessage = 'Tài khoản của bạn chỉ được phép truy cập trên trang Quản trị (CMS).';
              await logout(); // Force clear session
              _isLoading = false;
              notifyListeners();
              return;
            }

            _currentUser = user;
            _token = token;
            // Ensure userId is saved for API calls
            await _storageService.saveUserId(_currentUser!.id);
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login với API thật
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi API login
      final response = await _authApiService.login(
        username: username,
        password: password,
      );

      // Kiểm tra response
      if (response['success'] == true) {
        // Parse user từ response
        final userData = response['user'];
        if (userData != null) {
          final user = _authApiService.parseUser(userData);
          
          if (user == null) {
            _errorMessage = 'Lỗi thông tin người dùng';
             _isLoading = false;
            notifyListeners();
            return false;
          }

          // ROLE CHECK: Only Admin & Student can access Mobile
          if (!user.canAccessMobileApp) {
            _errorMessage = 'Tài khoản của bạn chỉ được phép truy cập trên trang Quản trị (CMS).';
            _isLoading = false;
            notifyListeners();
            return false;
          }

          _currentUser = user;
          _token = response['token'];

          await _storageService.saveToken(_token!); // Save token
          await _storageService.saveUserId(_currentUser!.id); // Save userId

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
          final user = _authApiService.parseUser(userData);
          
          if (user == null) {
            _errorMessage = 'Lỗi dữ liệu người dùng';
             _isLoading = false;
            notifyListeners();
            return false;
          }

          // ROLE CHECK: Only Admin & Student can access Mobile
          if (!user.canAccessMobileApp) {
             _errorMessage = 'Tài khoản của bạn chỉ được phép truy cập trên trang Quản trị (CMS).';
             await logout(); // Kick unauthorized role
             _isLoading = false;
             notifyListeners();
             return false;
          }

          _currentUser = user;
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

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? avatarUrl,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authApiService.updateProfile(
        name: name,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        avatarUrl: avatarUrl,
        token: _token,
      );

      if (response['success'] == true) {
        final userData = response['user'];
        if (userData != null) {
          final user = _authApiService.parseUser(userData);
          
          if (user == null) {
            _errorMessage = 'Lỗi cập nhật dữ liệu';
            _isLoading = false;
            notifyListeners();
            return false;
          }

          // ROLE CHECK: If role changed to unauthorized, logout
          if (!user.canAccessMobileApp) {
             _errorMessage = 'Tài khoản của bạn đã bị giới hạn quyền truy cập Mobile.';
             await logout();
             _isLoading = false;
             notifyListeners();
             return false;
          }

          _currentUser = user;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _errorMessage = response['message'] ?? 'Cập nhật thất bại';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi cập nhật: ${e.toString()}';
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
  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _errorMessage = null;
    await _storageService.removeToken(); // Remove token
    await _storageService.removeUserId(); // Remove userId
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Change password
  Future<bool> changePassword({
    String? oldPassword,
    required String newPassword,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authApiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        token: _token!,
      );

      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response['message'] ?? 'Đổi mật khẩu thất bại';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password lần đầu login
  Future<bool> changeFirstPassword({
    required String newPassword,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authApiService.changeFirstPassword(
        newPassword: newPassword,
        token: _token!,
      );

      if (response['success'] == true) {
        // Sau khi đổi thành công, cập nhật isFirstLogin = false local
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(isFirstLogin: false);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response['message'] ?? 'Đổi mật khẩu thất bại';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload Avatar
  Future<void> uploadAvatar(String filePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authApiService.uploadAvatar(filePath);
      if (response['success'] == true) {
        final updatedUser = response['user'];
        if (updatedUser != null) {
          final user = _authApiService.parseUser(updatedUser);
          
          if (user != null) {
            // ROLE CHECK: If role changed to unauthorized, logout
            if (!user.canAccessMobileApp) {
               _errorMessage = 'Tài khoản của bạn đã bị giới hạn quyền truy cập Mobile.';
               await logout();
               return;
            }
            
            _currentUser = user;
            await _storageService.saveUserId(_currentUser!.id);
          }
        }
      } else {
        throw Exception(response['message'] ?? 'Upload failed');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Upload avatar error: $e');
      rethrow; // Rethrow to let UI handle it (show snackbar)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

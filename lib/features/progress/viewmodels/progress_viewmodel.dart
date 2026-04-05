import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';

class ProgressViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Map<String, dynamic>? _userStats;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Tải thông tin thống kê người dùng (Best Scores, Target, etc.)
  Future<void> loadUserStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      final response = await _apiService.get(
        ApiConfig.usersMe,
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response['success'] == true) {
        _userStats = response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch user stats');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getters for display (Điểm Trung Bình thực tế)
  int get averageScore => _userStats?['averageScore'] ?? 0;
  int get totalAttempts => _userStats?['totalAttempts'] ?? 0;
  
  // TOEIC Burn Down (New Feature)
  int get targetScore => _userStats?['targetScore'] ?? 0;
  int get remainingGap => (targetScore - averageScore).clamp(0, 990);
  double get progressPercentage => targetScore > 0 ? (averageScore / targetScore).clamp(0.0, 1.0) : 0.0;
}

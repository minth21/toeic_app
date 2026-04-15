import 'package:flutter/material.dart';
import '../services/feedback_api_service.dart';

class FeedbackViewModel extends ChangeNotifier {
  final FeedbackApiService _apiService = FeedbackApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _history = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get history => _history;

  /// Load feedback history
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _apiService.getFeedbackHistory();
    } catch (e) {
      debugPrint('Error loading feedback history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send feedback
  Future<bool> sendFeedback({
    required String classId,
    required String content,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.sendFeedback(
        classId: classId,
        content: content,
      );

      if (response['success'] == true) {
        await loadHistory(); // Refresh history
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Gửi ý kiến thất bại';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

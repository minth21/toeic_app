import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class FeedbackApiService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Send feedback to teacher
  /// POST /api/feedbacks
  Future<Map<String, dynamic>> sendFeedback({
    required String classId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      final response = await _apiService.post(
        ApiConfig.feedbacks,
        body: {
          'classId': classId,
          'content': content,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
        headers: ApiConfig.headersWithAuth(token),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get student's feedback history
  /// GET /api/feedbacks
  Future<List<Map<String, dynamic>>> getFeedbackHistory() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      final response = await _apiService.get(
        ApiConfig.feedbacks,
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';
import '../models/flashcard_model.dart';

class VocabularyService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Lấy danh sách flashcards của người dùng
  Future<List<Flashcard>> getFlashcards() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      final response = await _apiService.get(
        ApiConfig.flashcards,
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => Flashcard.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch flashcards');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lưu danh sách flashcards mới (Bulk)
  Future<bool> saveFlashcards(List<Map<String, dynamic>> flashcards, String? partId) async {
    try {
      final token = await _storageService.getToken();
      final userId = await _storageService.getUserId();
      if (token == null || userId == null) throw Exception('Unauthorized');
      
      final response = await _apiService.post(
        '${ApiConfig.flashcards}/bulk',
        body: {
          'userId': userId,
          'flashcards': flashcards,
          'partId': partId,
        },
        headers: ApiConfig.headersWithAuth(token),
      );

      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Xóa flashcard
  Future<bool> deleteFlashcard(String id) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      final response = await _apiService.delete(
        '${ApiConfig.flashcards}/$id',
        headers: ApiConfig.headersWithAuth(token),
      );

      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

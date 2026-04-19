import 'dart:typed_data';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';
import '../models/ai_assessment.dart';

class AiTimelineService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Lấy danh sách lịch sử nhận xét AI (Timeline)
  /// userId: ID của học viên
  /// page: Trang cần lấy (mặc định 1)
  /// limit: Số lượng bản ghi mỗi trang (mặc định 20)
  Future<Map<String, dynamic>> getTimeline({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      final endpoint = '${ApiConfig.aiTimeline}/$userId?page=$page&limit=$limit';
      
      final response = await _apiService.get(
        endpoint,
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final assessments = data.map((json) => AiAssessment.fromJson(json)).toList();
        
        return {
          'success': true,
          'assessments': assessments,
          'meta': response['meta'],
        };
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch timeline');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy chi tiết một bản ghi đánh giá/lộ trình bằng ID
  Future<AiAssessment?> getAssessmentDetail(String id) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      final endpoint = '/ai/assessment/$id';
      
      final response = await _apiService.get(
        endpoint,
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response['success'] == true && response['data'] != null) {
        return AiAssessment.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Xuất PDF lộ trình
  Future<Uint8List> exportRoadmapPdf(String id) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      final endpoint = '/ai/export-roadmap-pdf/$id';
      
      return await _apiService.getBytes(
        endpoint,
        headers: ApiConfig.headersWithAuth(token),
      );
    } catch (e) {
      rethrow;
    }
  }
}

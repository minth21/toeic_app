import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';

class ClassApiService {
  final ApiService _apiService = ApiService();

  /// Lấy danh sách tài liệu bổ trợ của lớp
  /// GET /api/classes/:classId/materials
  Future<Map<String, dynamic>> getClassMaterials(String classId, String token) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.classMaterials}/$classId/materials',
        headers: ApiConfig.headersWithAuth(token),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Đánh dấu tài liệu là đã hoàn thành
  /// PATCH /api/classes/materials/:materialId/complete
  Future<Map<String, dynamic>> completeMaterial(String materialId, String token) async {
    try {
      final response = await _apiService.patch(
        '${ApiConfig.classMaterials}/materials/$materialId/toggle',
        body: {},
        headers: ApiConfig.headersWithAuth(token),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

import '../../../core/services/api_service.dart';

class DashboardApiService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getStudentDashboard() async {
    try {
      final response = await _apiService.get('/dashboard/student');
      if (response['success'] == true) {
        return response['data'];
      }
      throw Exception(response['message'] ?? 'Failed to load dashboard');
    } catch (e) {
      rethrow;
    }
  }
}

import '../models/notification_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/storage_service.dart';

class NotificationApiService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> getNotifications() async {
    final token = await _storageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await _apiService.get(
      ApiConfig.notifications,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response['success'] == true) {
      final List<dynamic> notificationsJson = response['data']['notifications'] ?? [];
      final List<NotificationModel> notifications = notificationsJson
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      return {
        'notifications': notifications,
        'unreadCount': response['data']['unreadCount'] ?? 0,
      };
    } else {
      throw Exception(response['message'] ?? 'Failed to load notifications');
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    final token = await _storageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await _apiService.patch(
      '${ApiConfig.notifications}/$notificationId/read',
      headers: ApiConfig.headersWithAuth(token),
    );

    return response['success'] == true;
  }

  Future<bool> markAllAsRead() async {
    final token = await _storageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await _apiService.patch(
      '${ApiConfig.notifications}/all/read',
      headers: ApiConfig.headersWithAuth(token),
    );

    return response['success'] == true;
  }
}

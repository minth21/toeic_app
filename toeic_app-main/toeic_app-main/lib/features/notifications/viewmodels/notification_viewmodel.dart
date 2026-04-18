import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationApiService _apiService = NotificationApiService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// Tải danh sách thông báo từ API
  Future<void> loadNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _apiService.getNotifications();
      _notifications = result['notifications'] as List<NotificationModel>;
      _unreadCount = result['unreadCount'] as int;
      
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đánh dấu một thông báo là đã đọc
  Future<void> markAsRead(String id) async {
    try {
      final success = await _apiService.markAsRead(id);
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = NotificationModel(
            id: _notifications[index].id,
            userId: _notifications[index].userId,
            title: _notifications[index].title,
            content: _notifications[index].content,
            type: _notifications[index].type,
            isRead: true,
            relatedId: _notifications[index].relatedId,
            createdAt: _notifications[index].createdAt,
          );
          if (_unreadCount > 0) _unreadCount--;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Đánh dấu tất cả là đã đọc
  Future<void> markAllAsRead() async {
    try {
      final success = await _apiService.markAllAsRead();
      if (success) {
        _notifications = _notifications.map((n) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            content: n.content,
            type: n.type,
            isRead: true,
            relatedId: n.relatedId,
            createdAt: n.createdAt,
          );
        }).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}

import 'package:intl/intl.dart';

enum NotificationType {
  newTestOpened,
  feedbackResolved,
  testApproved,
  testPending,
  system,
  studentFeedback,
  testSubmitted
}

extension NotificationTypeExtension on NotificationType {
  String get value => toString().split('.').last;
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final NotificationType type;
  final bool isRead;
  final String? relatedId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    this.relatedId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: _parseType(json['type']),
      isRead: json['isRead'] ?? false,
      relatedId: json['relatedId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']).toLocal() 
          : DateTime.now(),
    );
  }

  static NotificationType _parseType(String? type) {
    if (type == null) return NotificationType.system;
    switch (type) {
      case 'NEW_TEST_OPENED':
        return NotificationType.newTestOpened;
      case 'FEEDBACK_RESOLVED':
        return NotificationType.feedbackResolved;
      case 'TEST_APPROVED':
        return NotificationType.testApproved;
      case 'TEST_PENDING':
        return NotificationType.testPending;
      case 'SYSTEM':
        return NotificationType.system;
      case 'STUDENT_FEEDBACK':
        return NotificationType.studentFeedback;
      case 'TEST_SUBMITTED':
        return NotificationType.testSubmitted;
      default:
        return NotificationType.system;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}

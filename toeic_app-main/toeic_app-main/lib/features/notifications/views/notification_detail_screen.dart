import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification_model.dart';
import '../../../../constants/app_constants.dart';
import '../../practice/views/ai_assessment_detail_screen.dart';
import '../../practice/views/test_detail_screen.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chi tiết thông báo',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.premiumGradient,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.premiumShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTypeIcon(notification.type),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTypeLabel(notification.type),
                              style: GoogleFonts.inter(
                                color: AppColors.textHint,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              notification.timeAgo,
                              style: GoogleFonts.inter(
                                color: AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    notification.title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text(
                    notification.content,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            if (notification.relatedId != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleNavigateToRelated(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        _getButtonText(notification.type),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.newTestOpened:
      case NotificationType.testApproved:
        iconData = Icons.rocket_launch_rounded;
        color = AppColors.primary;
        break;
      case NotificationType.feedbackResolved:
        iconData = Icons.task_alt_rounded;
        color = AppColors.success;
        break;
      case NotificationType.roadmapReceived:
        iconData = Icons.alt_route_rounded;
        color = AppColors.secondary;
        break;
      default:
        iconData = Icons.notifications_rounded;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.newTestOpened:
        return 'BÀI THI MỚI';
      case NotificationType.feedbackResolved:
        return 'GÓP Ý';
      case NotificationType.testApproved:
        return 'ĐỀ THI';
      case NotificationType.roadmapReceived:
        return 'LỘ TRÌNH AI';
      default:
        return 'THÔNG BÁO';
    }
  }

  String _getButtonText(NotificationType type) {
    switch (type) {
      case NotificationType.roadmapReceived:
        return 'Xem lộ trình học tập';
      case NotificationType.newTestOpened:
      case NotificationType.testApproved:
        return 'Bắt đầu làm bài ngay';
      default:
        return 'Xem chi tiết nội dung';
    }
  }

  void _handleNavigateToRelated(BuildContext context) {
    if (notification.relatedId == null) return;

    switch (notification.type) {
      case NotificationType.roadmapReceived:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiAssessmentDetailScreen(assessmentId: notification.relatedId!),
          ),
        );
        break;
      case NotificationType.newTestOpened:
      case NotificationType.testApproved:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestDetailScreen(testId: notification.relatedId!),
          ),
        );
        break;
      default:
        // Other types navigation if needed
        break;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../../../constants/app_constants.dart';

class StudyJourneyTimeline extends StatelessWidget {
  final List<dynamic> timelineData;

  const StudyJourneyTimeline({
    super.key,
    required this.timelineData,
  });

  @override
  Widget build(BuildContext context) {
    if (timelineData.isEmpty) {
      return _buildEmptyState(context);
    }

    // Hiển thị tối đa 7 bài làm gần nhất trên trang chủ
    final displayData = timelineData.take(7).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          FixedTimeline.tileBuilder(
            theme: TimelineThemeData(
              nodePosition: 0,
              color: AppColors.primary,
              indicatorTheme: const IndicatorThemeData(
                position: 0,
                size: 20,
              ),
              connectorTheme: ConnectorThemeData(
                thickness: 2.5,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            builder: TimelineTileBuilder.connected(
              connectionDirection: ConnectionDirection.before,
              itemCount: displayData.length,
              contentsBuilder: (context, index) => _buildJourneyCard(context, displayData[index]),
              indicatorBuilder: (context, index) => _buildIndicator(context, displayData[index]),
              connectorBuilder: (context, index, type) => _buildConnector(context, displayData[index]),
            ),
          ),
          if (timelineData.length > 7) _buildSeeMoreButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'HÀNH TRÌNH HOÀNG KIM',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(BuildContext context, dynamic item) {
    final bool isMilestone = item['isMilestone'] ?? false;
    
    if (isMilestone) {
      return OutlinedDotIndicator(
        size: 24,
        color: AppColors.primary,
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: const Icon(Icons.emoji_events_rounded, size: 14, color: AppColors.primary),
      );
    }

    return DotIndicator(
      size: 16,
      color: AppColors.primary,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary,
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector(BuildContext context, dynamic item) {
    return const SolidLineConnector();
  }

  Widget _buildJourneyCard(BuildContext context, dynamic item) {
    final DateTime date = DateTime.parse(item['date']);
    final int partNum = item['partNumber'] ?? 0;
    final int score = item['score'] ?? 0;
    final int total = item['total'] ?? 0;
    final String comment = item['comment'] ?? '';
    final bool isMilestone = item['isMilestone'] ?? false;

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMilestone)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                item['milestoneLabel']?.toUpperCase() ?? 'CỘT MỐC MỚI',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMilestone ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                width: isMilestone ? 1.5 : 1,
              ),
              boxShadow: isMilestone ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Part $partNum: ${item['partName']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$score/$total',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        comment,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('HH:mm - dd/MM').format(date),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeeMoreButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          // Điều hướng đến trang Timeline chi tiết
        },
        child: const Text(
          'XEM TOÀN BỘ HÀNH TRÌNH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.history_edu_rounded, size: 48, color: AppColors.textHint),
            SizedBox(height: 16),
            Text(
              'Chưa có hành trình nào được ghi lại.\nBắt đầu luyện tập ngay!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

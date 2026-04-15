import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';

class ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;

  const ActivityHeatmap({super.key, required this.datasets});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Show current month's calendar starting from 1st
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0); // last day of month

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.softShadow,
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HÀNH TRÌNH CÀY CUỐC',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tháng ${now.month}/${now.year} 🚀',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Stats badge
              _buildStatsBadge(),
            ],
          ),

          const SizedBox(height: 20),

          // ── Heatmap ─────────────────────────────────────────────
          HeatMap(
            datasets: datasets,
            startDate: startDate,
            endDate: endDate,
            colorMode: ColorMode.color,
            showText: true,
            scrollable: false,
            size: 32,
            fontSize: 9,
            textColor: AppColors.textSecondary,
            defaultColor: const Color(0xFFF8FAFF),
            showColorTip: false,
            colorsets: const {
              1: Color(0xFFDDD6FE), // violet-200 – nhẹ nhàng
              2: Color(0xFFA78BFA), // violet-400
              3: Color(0xFF7C3AED), // violet-600
              5: Color(0xFF5B21B6), // violet-800
              7: Color(0xFF3B0764), // violet-950 – cực đậm
            },
            onClick: (date) {
              final count = datasets[date] ?? 0;
              if (count > 0) {
                _showDayTooltip(context, date, count);
              }
            },
          ),

          const SizedBox(height: 16),

          // ── Legend ──────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Ít hơn',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              ...const [
                Color(0xFFF8FAFF),
                Color(0xFFDDD6FE),
                Color(0xFFA78BFA),
                Color(0xFF7C3AED),
                Color(0xFF5B21B6),
              ].map(
                (c) => Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'Nhiều hơn',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Total this month
              Text(
                '${_totalThisMonth()} bài tháng này',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadge() {
    final activeDays = datasets.values.where((v) => v > 0).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.amberAccent, size: 16),
          const SizedBox(width: 4),
          Text(
            '$activeDays ngày',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  int _totalThisMonth() {
    return datasets.values.fold(0, (sum, v) => sum + v);
  }

  void _showDayTooltip(BuildContext context, DateTime date, int count) {
    final dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final dow = dayLabels[date.weekday % 7];
    final formatted = '$dow ${date.day}/${date.month}';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              '$formatted: $count bài luyện tập',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5B21B6),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }
}

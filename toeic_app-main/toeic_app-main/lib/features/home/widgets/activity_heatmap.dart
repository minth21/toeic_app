import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';

class ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final Map<DateTime, String> milestones;
  final int streak;

  const ActivityHeatmap({
    super.key, 
    required this.datasets, 
    required this.milestones,
    required this.streak,
  });


  @override
  Widget build(BuildContext context) {
    // Merge datasets: Historical Milestones take priority with value 100
    final combinedDatasets = Map<DateTime, int>.from(datasets);
    milestones.forEach((date, _) {
       combinedDatasets[date] = 100;
    });

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
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              // Stats badge
              _buildStatsBadge(streak),

            ],
          ),

          const SizedBox(height: 20),

          // ── Heatmap ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: HeatMapCalendar(
              datasets: combinedDatasets,
              colorMode: ColorMode.color,
              size: 37,
              fontSize: 12,
              margin: const EdgeInsets.all(3),
              textColor: AppColors.textSecondary,
              defaultColor: const Color(0xFFF1F5F9), // Light grey for no activity
              showColorTip: false,
              colorsets: const {
                1: Color(0xFFF5F3FF),
                2: Color(0xFFEDE9FE),
                3: Color(0xFFDDD6FE),
                4: Color(0xFFC4B5FD),
                5: Color(0xFFA78BFA),
                6: Color(0xFF8B5CF6),
                7: Color(0xFF7C3AED),
                100: Color(0xFF6D28D9), // Milestone
              },
              onClick: (date) {
                final milestoneLabel = milestones[date];
                if (milestoneLabel != null) {
                  _showMilestoneTooltip(context, date, milestoneLabel);
                } else {
                  final count = datasets[date] ?? 0;
                  if (count > 0) {
                    _showDayTooltip(context, date, count);
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Legend ──────────────────────────────────────────────
          Column(
            children: [
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
                    Color(0xFFF5F3FF),
                    Color(0xFFEDE9FE),
                    Color(0xFFDDD6FE),
                    Color(0xFFC4B5FD),
                    Color(0xFFA78BFA),
                    Color(0xFF8B5CF6),
                    Color(0xFF7C3AED),
                    Color(0xFF6D28D9),
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
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mốc kỷ niệm & Kỷ lục',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadge(int streakValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '$streakValue ngày cày',
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


  void _showMilestoneTooltip(BuildContext context, DateTime date, String label) {
    final dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final dow = dayLabels[date.weekday % 7];
    final formatted = '$dow ${date.day}/${date.month}';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'THÀNH TỰU CÀY CUỐC',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$formatted: $label',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber[900],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
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
            const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              '$formatted: Bạn đã cày $count phần cực sung!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.amber[900],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }
}

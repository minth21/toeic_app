import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../constants/app_constants.dart';
import '../viewmodels/progress_viewmodel.dart';
import '../../practice/viewmodels/ai_timeline_viewmodel.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../home/viewmodels/dashboard_viewmodel.dart';
import '../../practice/views/ai_assessment_detail_screen.dart';
import 'part_record_detail_screen.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {

  void _showTargetScoreDialog(BuildContext context, int currentScore) {
    final controller = TextEditingController(text: currentScore > 0 ? currentScore.toString() : '');
    final authViewModel = context.read<AuthViewModel>();
    final dashboardViewModel = context.read<DashboardViewModel>();
    final progressViewModel = context.read<ProgressViewModel>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.tr('target_score_dialog_title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('target_score_dialog_desc'),
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.tr('target_score_label'),
                hintText: context.tr('target_score_hint'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'), style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newScore = int.tryParse(controller.text);
              if (newScore == null || newScore < 0 || newScore > 990) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('invalid_score_msg'))),
                );
                return;
              }

              Navigator.pop(context); // Close dialog

              final success = await authViewModel.updateProfile(targetScore: newScore);
              if (success) {
                // Refresh all related data
                await dashboardViewModel.loadDashboard();
                await progressViewModel.loadUserStats();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: Text(context.tr('update_success')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authViewModel.errorMessage ?? 'Cập nhật thất bại'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(context.tr('update'), style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final progressVM = context.read<ProgressViewModel>();
      final timelineVM = context.read<AiTimelineViewModel>();
      final dashboardVM = context.read<DashboardViewModel>();
      final userId = context.read<AuthViewModel>().currentUser?.id;
      
      await progressVM.loadUserStats();
      if (userId != null && mounted) {
        await timelineVM.loadTimeline(userId);
        await dashboardVM.loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr('personal_achievement'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              final progressVM = context.read<ProgressViewModel>();
              progressVM.loadUserStats();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildScoreHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'LỘ TRÌNH MỤC TIÊU', Icons.auto_graph),
                  const SizedBox(height: 16),
                  _buildBurnDownCard(),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'AI COACH: TƯ VẤN CHIẾN THUẬT', Icons.psychology_alt_rounded),
                  const SizedBox(height: 16),
                  _buildAiCoachList(),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'KỶ LỤC TỪNG PHẦN', Icons.grid_view_rounded),
                  const SizedBox(height: 16),
                  _buildPartsGrid(context),
                  _buildSectionTitle(context, context.tr('performance_history'), Icons.trending_up),
                  const SizedBox(height: 16),
                  _buildPerformanceChart(),
                  const SizedBox(height: 32),
                  const SizedBox(height: 40), // Bottom padding

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Consumer<ProgressViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: const BoxDecoration(
            gradient: AppColors.premiumGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Column(
            children: [
              Text(
                'KỶ LỤC HIỆN TẠI',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${viewModel.estimatedScore}',
                    style: GoogleFonts.outfit(
                      fontSize: 84,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
              Text(
                'trên ${viewModel.targetScore > 0 ? viewModel.targetScore : 990} điểm',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                   _buildMasteryMiniCard(
                    'NGHE',
                    viewModel.estimatedListening,
                    495,
                    Icons.headphones,
                  ),
                  const SizedBox(width: 16),
                  _buildMasteryMiniCard(
                    'ĐỌC',
                    viewModel.estimatedReading,
                    495,
                    Icons.menu_book,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMasteryMiniCard(String label, int score, int max, IconData icon) {
    final progress = (score / max).clamp(0.0, 1.0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$score',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBurnDownCard() {
    return Consumer<ProgressViewModel>(
      builder: (context, viewModel, child) {
        final target = viewModel.targetScore;
        
        // Setup state if no target
        if (target <= 0) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
              boxShadow: AppShadows.softShadow,
            ),
            child: Column(
              children: [
                const Icon(Icons.track_changes_rounded, color: AppColors.primary, size: 48),
                const SizedBox(height: 16),
                Text(
                  'BẠN CHƯA CÓ MỤC TIÊU?',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy thiết lập mục tiêu điểm TOEIC để AI giúp bạn lập lộ trình học tập tối ưu.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showTargetScoreDialog(context, 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('THIẾT LẬP MỤC TIÊU NGAY'),
                  ),
                ),
              ],
            ),
          );
        }

        final gap = viewModel.remainingGap;
        final progress = viewModel.progressPercentage;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOEIC BURN DOWN',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${context.tr('target_score')}: $target ${context.tr('achievement_points_label').toLowerCase()}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showTargetScoreDialog(context, target),
                    icon: const Icon(Icons.edit_note_rounded, color: Colors.orangeAccent, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${(progress * 100).toInt()}% ${context.tr('completed')}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gap > 0 ? '$gap ${context.tr('points_to_go')}' : context.tr('target_achieved'),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceChart() {
    return Consumer<ProgressViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final target = viewModel.targetScore > 0 ? viewModel.targetScore.toDouble() : 990.0;
        final stats = viewModel.userStats;
        
        // Define total questions per part for normalization
        final totals = [6, 31, 39, 30, 30, 16, 54];
        
        final List<double> values = [];
        for (int i = 1; i <= 7; i++) {
          final score = (stats?['max_p$i'] ?? 0).toDouble();
          final max = totals[i - 1].toDouble();
          // Scale percentage to the target score
          values.add((score / max) * target);
        }

        return Container(
          height: 300,
          padding: const EdgeInsets.fromLTRB(12, 24, 20, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.softShadow,
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: target,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: AppColors.primary,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final actualScore = stats?['max_p${groupIndex + 1}'] ?? 0;
                    final total = totals[groupIndex];
                    return BarTooltipItem(
                      'Part ${groupIndex + 1}\n',
                      GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                         TextSpan(
                          text: '$actualScore/$total câu',
                          style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.normal, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'P${value.toInt() + 1}',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == target || value == (target / 2).roundToDouble()) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: target / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: values.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: target,
                        color: AppColors.indigo50,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }


  Widget _buildPartsGrid(BuildContext context) {
    return Consumer<ProgressViewModel>(
      builder: (context, viewModel, child) {
        final List<Map<String, dynamic>> parts = [
          {'name': 'Part 1', 'score': viewModel.userStats?['max_p1'] ?? 0, 'total': 6, 'icon': Icons.image_outlined},
          {'name': 'Part 2', 'score': viewModel.userStats?['max_p2'] ?? 0, 'total': 31, 'icon': Icons.record_voice_over_outlined},
          {'name': 'Part 3', 'score': viewModel.userStats?['max_p3'] ?? 0, 'total': 39, 'icon': Icons.forum_outlined},
          {'name': 'Part 4', 'score': viewModel.userStats?['max_p4'] ?? 0, 'total': 30, 'icon': Icons.campaign_outlined},
          {'name': 'Part 5', 'score': viewModel.userStats?['max_p5'] ?? 0, 'total': 30, 'icon': Icons.text_fields_outlined},
          {'name': 'Part 6', 'score': viewModel.userStats?['max_p6'] ?? 0, 'total': 16, 'icon': Icons.edit_note_outlined},
          {'name': 'Part 7', 'score': viewModel.userStats?['max_p7'] ?? 0, 'total': 54, 'icon': Icons.article_outlined},
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: parts.length,
          itemBuilder: (context, index) {
            final part = parts[index];
            final partNumber = index + 1;
            final partId = viewModel.userStats?['id_p$partNumber'];
            final p = (part['score'] / part['total']).toDouble();
            
            return GestureDetector(
              onTap: partId != null ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PartRecordDetailScreen(
                      partId: partId,
                      partName: part['name'],
                      partNumber: partNumber,
                    ),
                  ),
                );
              } : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hãy làm ít nhất một bài tập ở Part này để xem chi tiết.')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.softShadow,
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                      children: [
                        Icon(part['icon'], size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          part['name'],
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${part['score']}/${part['total']}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p,
                        backgroundColor: AppColors.indigo50,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          p >= 0.8 ? AppColors.success : (p >= 0.4 ? AppColors.primary : AppColors.warning)
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.indigo50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiCoachList() {
    return Consumer<AiTimelineViewModel>(
      builder: (context, timelineVM, child) {
        if (timelineVM.isLoading && timelineVM.assessments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final assessments = timelineVM.assessments;
        if (assessments.isEmpty) {
          return _buildChartPlaceholder(context, 'Chưa có tư vấn chiến thuật nào từ AI.');
        }

        return Column(
          children: [
            ...assessments.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.softShadow,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm - dd/MM/yyyy').format(item.createdAt),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem chi tiết',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                  ],
                ),
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AiAssessmentDetailScreen(assessment: item),
                    ),
                  );
                },
              ),
            )),
          ],
        );
      },
    );
  }


  

  Widget _buildChartPlaceholder(BuildContext context, String message) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.softShadow,
      ),
      child: Center(
        child: Text(message, style: GoogleFonts.outfit(color: Colors.grey.shade500)),
      ),
    );
  }

}

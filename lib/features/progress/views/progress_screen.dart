import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../viewmodels/progress_viewmodel.dart';
import '../../practice/viewmodels/ai_timeline_viewmodel.dart';
import '../../practice/models/ai_assessment.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final progressVM = context.read<ProgressViewModel>();
      await progressVM.loadUserStats();
      if (!mounted) return;
      
      final userId = progressVM.userStats?['id'];
      if (userId != null) {
        context.read<AiTimelineViewModel>().loadTimeline(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Thành tích cá nhân',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              final progressVM = context.read<ProgressViewModel>();
              progressVM.loadUserStats();
              final userId = progressVM.userStats?['id'];
              if (userId != null) {
                context.read<AiTimelineViewModel>().loadTimeline(userId);
              }
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
                  _buildSectionTitle('Lịch sử phong độ', Icons.trending_up),
                  const SizedBox(height: 16),
                  _buildPerformanceChart(),
                  const SizedBox(height: 32),
                  _buildBurnDownCard(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Tư vấn chiến thuật AI', Icons.auto_awesome),
                  const SizedBox(height: 16),
                  _buildAITimeline(),
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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              Text(
                'ĐIỂM TRUNG BÌNH HIỆN TẠI',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Text(
                    '${viewModel.averageScore}',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSkillCard(
                      'Số bài đã làm',
                      viewModel.totalAttempts,
                      Icons.history_edu_rounded,
                      Colors.blue.shade100,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSkillCard(
                      'Mục tiêu',
                      viewModel.targetScore,
                      Icons.flag_rounded,
                      Colors.green.shade100,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBurnDownCard() {
    return Consumer<ProgressViewModel>(
      builder: (context, viewModel, child) {
        final target = viewModel.targetScore;
        if (target <= 0) return const SizedBox.shrink();

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOEIC BURN DOWN',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mục tiêu: $target điểm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 32),
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
                  Text(
                    '${(progress * 100).toInt()}% Hoàn thành',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    gap > 0 ? '$gap điểm nữa!' : 'Đã đạt mục tiêu! 🎉',
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

  Widget _buildSkillCard(String skill, int score, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Consumer<AiTimelineViewModel>(
      builder: (context, timelineVM, child) {
        if (timelineVM.isLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final assessments = timelineVM.assessments.reversed.toList();
        if (assessments.isEmpty) {
          return _buildChartPlaceholder('Hãy thi thử để bắt đầu ghi lại thành tích');
        }

        final points = assessments.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.score?.toDouble() ?? 0);
        }).toList();

        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 1000,
              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 4,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAITimeline() {
    return Consumer<AiTimelineViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.assessments.isEmpty) {
          return const Center(
            child: Text('Chưa có nhận xét AI nào.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.assessments.length,
          itemBuilder: (context, index) {
            final assessment = viewModel.assessments[index];
            return _buildTimelineItem(assessment);
          },
        );
      },
    );
  }

  Widget _buildTimelineItem(AiAssessment assessment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.indigo50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(assessment.createdAt),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (assessment.score != null)
                Text(
                  '${assessment.score}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            assessment.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          HtmlWidget(
            assessment.summary,
            textStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChartPlaceholder(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey.shade500)),
      ),
    );
  }
}

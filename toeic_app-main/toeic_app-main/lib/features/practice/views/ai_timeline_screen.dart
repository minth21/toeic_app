import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../models/ai_assessment.dart';
import '../viewmodels/ai_timeline_viewmodel.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import 'ai_assessment_detail_screen.dart';

class AiTimelineScreen extends StatefulWidget {
  const AiTimelineScreen({super.key});

  @override
  State<AiTimelineScreen> createState() => _AiTimelineScreenState();
}

class _AiTimelineScreenState extends State<AiTimelineScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final userId = authViewModel.currentUser?.id;
      if (userId != null) {
        context.read<AiTimelineViewModel>().loadTimeline(userId);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        final userId = authViewModel.currentUser?.id;
        if (userId != null) {
          context.read<AiTimelineViewModel>().loadMore(userId);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? AppColors.background 
          : AppColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Lộ trình tư vấn AI'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.premiumGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AiTimelineViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.assessments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null && viewModel.assessments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(viewModel.error!),
                  ElevatedButton(
                    onPressed: () {
                      final userId = context.read<AuthViewModel>().currentUser?.id;
                      if (userId != null) viewModel.loadTimeline(userId);
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.assessments.isEmpty) {
            return const Center(
              child: Text('Chưa có nhận xét nào từ AI. Hãy bắt đầu luyện tập ngay!'),
            );
          }

          final groupedData = viewModel.groupedAssessments;
          final dates = groupedData.keys.toList();

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = dates[index];
                      final items = groupedData[date]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateHeader(date),
                          const SizedBox(height: 16),
                          FixedTimeline.tileBuilder(
                            theme: TimelineThemeData(
                              nodePosition: 0,
                              connectorTheme: const ConnectorThemeData(
                                thickness: 3.0,
                                color: AppColors.divider,
                              ),
                              indicatorTheme: const IndicatorThemeData(
                                size: 20.0,
                              ),
                            ),
                            builder: TimelineTileBuilder.connected(
                              indicatorBuilder: (context, idx) => _buildIndicator(items[idx]),
                              connectorBuilder: (context, idx, type) => _buildConnector(items[idx]),
                              contentsBuilder: (context, idx) => _buildAssessmentCard(items[idx]),
                              itemCount: items.length,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                    childCount: dates.length,
                  ),
                ),
              ),
              if (viewModel.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    String dateStr;
    if (date == today) {
      dateStr = 'Hôm nay';
    } else if (date == yesterday) {
      dateStr = 'Hôm qua';
    } else {
      dateStr = DateFormat('dd MMMM, yyyy', 'vi').format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateStr,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildIndicator(AiAssessment assessment) {
    Color color;
    IconData icon;

    switch (assessment.type) {
      case AiAssessmentType.performance:
        color = AppColors.info;
        icon = Icons.analytics;
        break;
      case AiAssessmentType.coaching:
        color = AppColors.warning;
        icon = Icons.lightbulb_outline;
        break;
      case AiAssessmentType.explanation:
        color = AppColors.secondary;
        icon = Icons.book_outlined;
        break;
      case AiAssessmentType.roadmap:
        color = Colors.green;
        icon = Icons.flag;
        break;
    }

    return DotIndicator(
      color: color,
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }

  Widget _buildConnector(AiAssessment assessment) {
    return const SolidLineConnector();
  }

  Widget _buildAssessmentCard(AiAssessment assessment) {
    Color accentColor;
    switch (assessment.type) {
      case AiAssessmentType.performance: accentColor = AppColors.info; break;
      case AiAssessmentType.coaching: accentColor = AppColors.warning; break;
      case AiAssessmentType.explanation: accentColor = AppColors.secondary; break;
      case AiAssessmentType.roadmap: accentColor = Colors.green; break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.softShadow,
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AiAssessmentDetailScreen(assessment: assessment),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            assessment.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (assessment.score != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${assessment.score}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        _buildTrendIcon(assessment.trend),
                      ],
                    ),
                    const SizedBox(height: 8),
                    HtmlWidget(
                      assessment.summary,
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.light
                            ? AppColors.textSecondary
                            : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm').format(assessment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIcon(TrendType? trend) {
    if (trend == null) return const SizedBox.shrink();
    
    IconData icon;
    Color color;

    switch (trend) {
      case TrendType.up:
        icon = Icons.trending_up;
        color = AppColors.success;
        break;
      case TrendType.down:
        icon = Icons.trending_down;
        color = AppColors.error;
        break;
      case TrendType.stable:
        icon = Icons.trending_flat;
        color = AppColors.info;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

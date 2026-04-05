import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../navigation/viewmodels/navigation_viewmodel.dart';
import '../../vocabulary/viewmodels/vocabulary_viewmodel.dart';
import '../../progress/viewmodels/progress_viewmodel.dart';
import '../../practice/viewmodels/ai_timeline_viewmodel.dart';
import '../../practice/viewmodels/practice_viewmodel.dart';
import '../../practice/models/part_model.dart';
import '../../practice/views/practice_result_screen.dart';
import '../widgets/activity_chart.dart';
import '../widgets/activity_heatmap.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/models/user_model.dart';
import '../../class/views/class_materials_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _loadingActivityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<DashboardViewModel>().loadDashboard();
      context.read<VocabularyViewModel>().loadFlashcards();
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
    final dashboardViewModel = context.watch<DashboardViewModel>();

    if (dashboardViewModel.isLoading && dashboardViewModel.dashboardData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Prefer name from AuthViewModel (available immediately after login)
    // Fallback to dashboard API response
    final authUser = context.watch<AuthViewModel>().currentUser;
    final displayName = authUser?.name.isNotEmpty == true
        ? authUser!.name
        : dashboardViewModel.userName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => dashboardViewModel.loadDashboard(),
        child: CustomScrollView(
          slivers: [
            // A. SliverAppBar (Welcome Banner & Streak)
            _buildSliverAppBar(displayName, dashboardViewModel.streak),

            // B. Hero Card (Mục tiêu & Điểm số)
            SliverToBoxAdapter(
              child: Consumer<ProgressViewModel>(
                builder: (context, progressVM, _) => _buildHeroCard(
                  progressVM.averageScore,
                  0, // Listening average not added yet but kept for UI
                  0, // Reading average not added yet but kept for UI
                ),
              ),
            ),

            // B2. Lớp học của tôi (Supplementary Materials Entry)
            SliverToBoxAdapter(
              child: Consumer<AuthViewModel>(
                builder: (context, authVM, _) {
                  final user = authVM.currentUser;
                  if (user?.classId == null) return const SizedBox.shrink();
                  return _buildClassCard(context, user!);
                },
              ),
            ),

            // C. Quick Categories (Menu Kỹ năng)
            SliverToBoxAdapter(
              child: _buildQuickCategories(context),
            ),

            // D. Recent AI Wisdom (Tư vấn chiến thuật)
            SliverToBoxAdapter(
              child: _buildRecentAIAdvice(context),
            ),

            // E. Recent Activity
            _buildRecentActivity(dashboardViewModel),
            
            // F. Activity Frequency Chart (Bar)
            SliverToBoxAdapter(
              child: ActivityChart(stats: dashboardViewModel.activityStats),
            ),

            // G. Activity Heatmap (Monthly calendar)
            SliverToBoxAdapter(
              child: ActivityHeatmap(datasets: dashboardViewModel.heatmapData),
            ),

            // Bottom Padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String userName, int streak) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Row 1: Welcome + Notifications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chào $userName! 👋',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.softShadow,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_rounded,
                            color: AppColors.textPrimary),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Tagline + Streak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Hôm nay bạn muốn học gì?',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(int totalScore, int listeningScore, int readingScore) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.premiumShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'ĐIỂM TRUNG BÌNH',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalScore',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSkillScore(Icons.headphones, 'Listening', listeningScore),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              _buildSkillScore(Icons.menu_book, 'Reading', readingScore),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillScore(IconData icon, String label, int score) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
        Text(
          '$score',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _buildQuickCategories(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCategoryCard(
                  'Nghe',
                  Icons.headphones_rounded,
                  AppColors.indigo50,
                  AppColors.primary,
                  onTap: () {
                    context.read<PracticeViewModel>().setSkillFilter('listening');
                    context.read<NavigationViewModel>().setIndex(1);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryCard(
                  'Đọc',
                  Icons.menu_book_rounded,
                  const Color(0xFFF0FDF4),
                  AppColors.success,
                  onTap: () {
                    context.read<PracticeViewModel>().setSkillFilter('reading');
                    context.read<NavigationViewModel>().setIndex(1);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Consumer<VocabularyViewModel>(
                  builder: (context, vm, _) => _buildCategoryCard(
                    'Từ Vựng',
                    Icons.style_outlined,
                    const Color(0xFFFEF9C3),
                    AppColors.warning,
                    subtitle: '${vm.flashcards.length} thẻ',
                    onTap: () {
                      context.read<NavigationViewModel>().setIndex(2); // Go to Vocabulary Tab
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryCard(
                  'Tiến độ',
                  Icons.bar_chart_rounded,
                  const Color(0xFFFDF2F8),
                  const Color(0xFFEC4899),
                  subtitle: 'Xem phân tích',
                  onTap: () {
                    context.read<NavigationViewModel>().setIndex(3); // Go to Progress Tab
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.softShadow,
      ),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: iconColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAIAdvice(BuildContext context) {
    return Consumer<AiTimelineViewModel>(
      builder: (context, vm, _) {
        if (vm.assessments.isEmpty) return const SizedBox.shrink();
        final latest = vm.assessments.first;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Chiến thuật AI mới nhất',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppShadows.softShadow,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latest.summary.replaceAll(RegExp(r'<[^>]*>'), ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        DefaultTabController.of(context).animateTo(3);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Xem chi tiết phân tích'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(DashboardViewModel vm) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (vm.recentActivities.isNotEmpty) ...[
            Text(
              'Hoạt động gần đây',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...vm.recentActivities.map((act) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecentActivityItem(
                    '${act['title']} - ${act['partName']}',
                    '${act['score']}/${act['totalQuestions']}',
                    _formatTimeDiff(act['createdAt']),
                    isLoading: _loadingActivityId == act['id'],
                    onTap: _loadingActivityId != null ? null : () async {
                      setState(() => _loadingActivityId = act['id']);
                      
                      try {
                        final practiceVM = context.read<PracticeViewModel>();
                        final detail = await practiceVM.loadAttemptDetail(act['id']);
                        
                        if (detail != null && mounted) {
                          // Construct PartModel from detail data
                          final partData = detail['part'] as Map<String, dynamic>;
                          final partModel = PartModel.fromJson(partData);
                          
                          // Consstruct result data
                          final resultData = {
                            'score': detail['correctCount'],
                            'totalQuestions': detail['totalQuestions'],
                            'toeicScore': detail['totalScore'] ?? detail['toeicScore'],
                            'percentage': ((detail['correctCount'] / detail['totalQuestions']) * 100).toDouble(),
                          };

                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PracticeResultScreen(
                                  resultData: resultData,
                                  part: partModel,
                                  attemptId: act['id'],
                                ),
                              ),
                            );
                          }
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể tải chi tiết bài làm. Vui lòng thử lại sau.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi kết nối: ${e.toString()}'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _loadingActivityId = null);
                        }
                      }
                    },
                  ),
                )),
          ],
        ]),
      ),
    );
  }

  Widget _buildRecentActivityItem(String title, String score, String time, {VoidCallback? onTap, bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                isLoading 
                  ? const SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                    )
                  : const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  score,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeDiff(String createdAt) {
    final date = DateTime.parse(createdAt);
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  Widget _buildClassCard(BuildContext context, UserModel user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.softShadow,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClassMaterialsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lớp: ${user.className ?? "Đang tải..."}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'GV: ${user.teacherName ?? "Trung tâm Antigravity"}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tài liệu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

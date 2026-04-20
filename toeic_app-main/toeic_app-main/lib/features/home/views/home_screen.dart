import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_typography.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../navigation/viewmodels/navigation_viewmodel.dart';
import '../../vocabulary/viewmodels/vocabulary_viewmodel.dart';
import '../../progress/viewmodels/progress_viewmodel.dart';

import '../../practice/viewmodels/practice_viewmodel.dart';
import '../widgets/activity_chart.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/models/user_model.dart';
import '../../class/views/class_materials_screen.dart';
import '../../notifications/viewmodels/notification_viewmodel.dart';
import '../../notifications/views/notification_screen.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<DashboardViewModel>().loadDashboard();
      context.read<VocabularyViewModel>().loadFlashcards();
      final progressVM = context.read<ProgressViewModel>();
      await progressVM.loadUserStats();
    });
  }

  String _getAiDynamicTagline(int currentScore, int targetScore) {
    if (currentScore == 0) return '🚀 Bắt đầu bài thi thử để AI lập lộ trình cho bạn nhé!';
    
    final gap = targetScore - currentScore;
    final List<String> taglines = [
      '🔥 Bạn chỉ còn cách mục tiêu $gap điểm nữa thôi. Cố lên!',
      '💡 Mẹo nhỏ: Tập trung vào Part 5 để gỡ điểm ngữ pháp nhanh nhất.',
      '🎧 Đừng quên luyện nghe 15 phút mỗi sáng để nhạy bén hơn nhé.',
      '📚 Hôm nay hãy thử chinh phục 10 từ vựng Part 7 xem sao?',
      '🎯 Tập trung vào những phần bạn còn yếu để bứt phá điểm số.',
      '✨ AI đã cập nhật chiến thuật mới dựa trên kết quả hôm qua của bạn.'
    ];
    
    // Simple rotation based on day or score to feel "alive"
    return taglines[DateTime.now().second % taglines.length];
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => dashboardViewModel.loadDashboard(),
        child: CustomScrollView(
          slivers: [
            // A. SliverAppBar (Welcome Banner & Streak)
            _buildSliverAppBar(displayName, dashboardViewModel, authUser),

            // B. Hero Card (Mục tiêu & Điểm số)
            SliverToBoxAdapter(
              child: _buildHeroCard(
                dashboardViewModel.predictedScore > 0
                    ? dashboardViewModel.predictedScore
                    : context.watch<ProgressViewModel>().totalScore,
                dashboardViewModel.listeningScore > 0
                    ? dashboardViewModel.listeningScore
                    : context.watch<ProgressViewModel>().listeningScore,
                dashboardViewModel.readingScore > 0
                    ? dashboardViewModel.readingScore
                    : context.watch<ProgressViewModel>().readingScore,
                // Ưu tiên lấy targetScore từ AuthViewModel (đã set bên tab tiến độ)
                authUser?.targetScore ?? context.watch<ProgressViewModel>().targetScore,
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

            // C. AI Coaching Section (Gia sư AI)
            if (dashboardViewModel.recommendations.isNotEmpty)
              _buildAiCoachingSection(dashboardViewModel),

            // D. Quick Categories (Menu Kỹ năng)
            SliverToBoxAdapter(
              child: _buildQuickCategories(context),
            ),
            
            // E. Recent Activity Section (RESTORED)
            _buildRecentActivitySection(dashboardViewModel.recentActivities),

            // F. Activity Frequency Chart (Bar)
            SliverToBoxAdapter(
              child: ActivityChart(stats: dashboardViewModel.activityStats),
            ),

            // Bottom Padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String userName, DashboardViewModel dashboardViewModel, UserModel? authUser) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      '${context.tr('welcome')} $userName! 👋',
                      style: AppTypography.friendly(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.displayLarge?.color ?? AppColors.textPrimary,
                      ),
                    ),
                    Consumer<NotificationViewModel>(
                      builder: (context, notificationVM, child) {
                        return Badge(
                          label: Text('${notificationVM.unreadCount}'),
                          isLabelVisible: notificationVM.unreadCount > 0,
                          backgroundColor: AppColors.error,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.softShadow,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.notifications_none_rounded,
                                  color: Theme.of(context).textTheme.bodyLarge?.color),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                                );
                              },
                            ),
                          ),
                        );
                      },
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
                        _getAiDynamicTagline(
                          dashboardViewModel.predictedScore > 0 ? dashboardViewModel.predictedScore : context.watch<ProgressViewModel>().totalScore,
                          authUser?.targetScore ?? 500
                        ),
                        style: AppTypography.friendly(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: (Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary)
                              .withValues(alpha: 0.8),
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

  Widget _buildHeroCard(int totalScore, int listeningScore, int readingScore, int targetScore) {
    final gap = targetScore - totalScore;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.premiumShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'ĐIỂM TỔNG TOEIC',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, color: Colors.amberAccent, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Mục tiêu: $targetScore',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalScore',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              if (gap > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8),
                  child: Text(
                    '-$gap to target',
                    style: GoogleFonts.inter(
                      color: Colors.amberAccent.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSkillScore(Icons.headphones, context.tr('listening'), listeningScore),
              Container(
                width: 1,
                height: 20,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              _buildSkillScore(Icons.menu_book, context.tr('reading'), readingScore),
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


  Widget _buildAiCoachingSection(DashboardViewModel vm) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'GIA SƯ AI: TƯ VẤN CHIẾN THUẬT',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary.withValues(alpha: 0.8),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...vm.recommendations.take(2).map((rec) => _buildAiCoachCard(rec)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _buildAiCoachCard(dynamic rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.softShadow,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
             // Link to Progress tab when clicking advice
             context.read<NavigationViewModel>().setIndex(3);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rec['icon'] == 'warning' ? Icons.lightbulb_rounded : Icons.auto_awesome, 
                    color: Colors.amber, 
                    size: 20
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec['title'] ?? 'Chiến thuật gợi ý',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec['subtitle'] ?? 'Hãy xem chi tiết phân tích từ AI.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
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
                  context.tr('listening'),
                  Icons.headphones_rounded,
                  AppColors.primary.withValues(alpha: 0.1),
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
                  context.tr('reading'),
                  Icons.menu_book_rounded,
                  AppColors.success.withValues(alpha: 0.1),
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
                    context.tr('vocabulary'),
                    Icons.style_outlined,
                    AppColors.warning.withValues(alpha: 0.1),
                    AppColors.warning,
                    subtitle: '${vm.flashcards.length} ${context.tr('cards')}',
                    onTap: () {
                      context.read<NavigationViewModel>().setIndex(2);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryCard(
                  context.tr('progress'),
                  Icons.bar_chart_rounded,
                  const Color(0xFFEC4899).withValues(alpha: 0.1),
                  const Color(0xFFEC4899),
                  subtitle: context.tr('view_analytics'),
                  onTap: () {
                    context.read<NavigationViewModel>().setIndex(3);
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
        color: Theme.of(context).cardColor,
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
                    color: Theme.of(context).scaffoldBackgroundColor,
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
                          color: Theme.of(context).textTheme.titleMedium?.color,
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



  Widget _buildClassCard(BuildContext context, UserModel user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                        '${context.tr('class')}: ${user.className ?? context.tr('loading')}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.tr('teacher')}: ${user.teacherName ?? "Antigravity Center"}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
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
                  child: Text(
                    context.tr('materials'),
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

  Widget _buildRecentActivitySection(List<dynamic> activities) {
    if (activities.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LUYỆN TẬP GẦN ĐÂY',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.take(3).map((activity) => _buildRecentActivityCard(activity)),
        ]),
      ),
    );
  }

  Widget _buildRecentActivityCard(dynamic activity) {
    final int percentage = activity['percentage'] ?? 0;
    final bool isCorrect = percentage >= 50; // Đưa về 50% để bài làm hôm qua hiện Xanh đúng chuẩn

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCorrect ? Icons.check_circle_outline : Icons.highlight_off_rounded,
            color: isCorrect ? AppColors.success : AppColors.error,
            size: 24,
          ),
        ),
        title: Text(
          'Part ${activity['partNumber']}: ${activity['partName']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          activity['title'] ?? 'Luyện tập',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCorrect ? AppColors.success : AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCorrect ? 'ĐÚNG' : 'SAI',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${activity['score']}/${activity['totalQuestions']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

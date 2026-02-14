import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../models/exam_model.dart';
import '../viewmodels/practice_viewmodel.dart';
import 'test_detail_screen.dart';
// import '../../auth/viewmodels/auth_viewmodel.dart'; // Unused
import '../../../l10n/app_localizations.dart';

/// Practice Screen - Student-Centric Design with Difficulty Filter
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  void initState() {
    super.initState();
    // Load tests on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PracticeViewModel>().loadTests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('practice') ?? 'Luyện tập',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PracticeViewModel>().loadTests();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty Filter Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterChip(
                      context,
                      AppLocalizations.of(context)?.translate('all') ??
                          'Tất cả',
                      null,
                    ),
                    _buildFilterChip(
                      context,
                      AppLocalizations.of(context)?.translate('easy') ?? 'Dễ',
                      'EASY',
                    ),
                    _buildFilterChip(
                      context,
                      AppLocalizations.of(context)?.translate('medium') ??
                          'Trung bình',
                      'MEDIUM',
                    ),
                    _buildFilterChip(
                      context,
                      AppLocalizations.of(context)?.translate('hard') ?? 'Khó',
                      'HARD',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Test List Section
          Expanded(
            child: Consumer<PracticeViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                                context,
                              )?.translate('error_occurred') ??
                              'Có lỗi xảy ra',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          viewModel.error!,
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: viewModel.loadTests,
                          child: Text(
                            AppLocalizations.of(context)?.translate('retry') ??
                                'Thử lại',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.tests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                                context,
                              )?.translate('no_tests_found') ??
                              'Không tìm thấy đề thi nào',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: viewModel.loadTests,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.tests.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final test = viewModel.tests[index];
                      return _buildTestCard(context, test);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String? difficultyValue,
  ) {
    final viewModel = context.watch<PracticeViewModel>();
    final isSelected = viewModel.selectedDifficulty == difficultyValue;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        context.read<PracticeViewModel>().setDifficulty(
          selected ? difficultyValue : null,
        );
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.poppins(
        color: isSelected
            ? AppColors.primary
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      showCheckmark:
          false, // Cleaner look without checkmark if desired, or keep it
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildTestCard(BuildContext context, ExamModel test) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TestDetailScreen(test: test),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildDifficultyBadge(test.difficulty),
                    const Spacer(),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${test.duration} ${AppLocalizations.of(context)?.translate('minutes')}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  test.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12), // Increased spacing
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        Icons.format_list_numbered,
                        '${test.totalQuestions} ${AppLocalizations.of(context)?.translate('questions')}',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        Icons.headphones,
                        '${test.listeningQuestions}',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        Icons.menu_book,
                        '${test.readingQuestions}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestDetailScreen(test: test),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.translate('start_now') ??
                          'Làm bài ngay',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    String text;

    switch (difficulty) {
      case 'EASY':
        color = const Color(0xFF4CAF50);
        text = AppLocalizations.of(context)?.translate('easy') ?? 'Dễ';
        break;
      case 'MEDIUM':
        color = const Color(0xFFFF9800);
        text =
            AppLocalizations.of(context)?.translate('medium') ?? 'Trung bình';
        break;
      case 'HARD':
        color = const Color(0xFFF44336);
        text = AppLocalizations.of(context)?.translate('hard') ?? 'Khó';
        break;
      default:
        color = Colors.grey;
        text = difficulty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Avoid expansion if not needed
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Flexible(
          // Handle long text
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

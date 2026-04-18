import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../models/exam_model.dart';
import '../viewmodels/practice_viewmodel.dart';
import 'test_detail_screen.dart';
import 'practice_history_screen.dart';
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
          context.tr('practice'),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PracticeHistoryScreen(),
                ),
              );
            },
          ),
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
          // Modern Structured Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<PracticeViewModel>(
                builder: (context, vm, _) {
                  final isNoFilter = vm.selectedDifficulty == null && vm.selectedSkill == null;
                  
                  return Row(
                    children: [
                      // 1. CLEAR ALL BUTTON
                      ActionChip(
                        onPressed: () {
                          vm.setDifficulty(null);
                          vm.setSkillFilter(null);
                        },
                        label: Text(context.tr('all')),
                        avatar: isNoFilter 
                          ? const Icon(Icons.done_all, size: 16, color: Colors.white) 
                          : const Icon(Icons.clear_all, size: 16, color: AppColors.primary),
                        backgroundColor: isNoFilter ? AppColors.primary : Theme.of(context).cardColor,
                        labelStyle: GoogleFonts.inter(
                          color: isNoFilter ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isNoFilter ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      
                      const VerticalDivider(width: 24, thickness: 1, indent: 8, endIndent: 8),

                      // 2. SKILL GROUP
                      Text(
                        '${context.tr('skills')}:',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      _buildSkillChip(context, context.tr('listening'), 'listening'),
                      const SizedBox(width: 6),
                      _buildSkillChip(context, context.tr('reading'), 'reading'),

                      const VerticalDivider(width: 24, thickness: 1, indent: 8, endIndent: 8),

                      // 3. LEVEL GROUP
                      Text(
                        '${context.tr('difficulty_level')}:',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'A1-A2', 'A1_A2'),
                      const SizedBox(width: 6),
                      _buildFilterChip(context, 'B1-B2', 'B1_B2'),
                      const SizedBox(width: 6),
                      _buildFilterChip(context, 'C1', 'C1'),
                    ],
                  );
                },
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
                               context.tr('error_occurred'),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          viewModel.error!,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: viewModel.loadTests,
                          child: Text(
                               context.tr('retry'),
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
                               context.tr('no_tests_found'),
                          style: GoogleFonts.inter(
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
      labelStyle: GoogleFonts.inter(
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

  Widget _buildSkillChip(
    BuildContext context,
    String label,
    String? skillValue,
  ) {
    final viewModel = context.watch<PracticeViewModel>();
    final isSelected = viewModel.selectedSkill == skillValue;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        context.read<PracticeViewModel>().setSkillFilter(
              selected ? skillValue : null,
            );
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      showCheckmark: false,
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
                    if (test.status == 'PENDING')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'SẮP RA MẮT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${test.duration} ${context.tr('minutes')}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  test.title.isNotEmpty ? test.title : 'Unknown Test',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
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
                        '${test.totalQuestions} ${context.tr('questions')}',
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
                    onPressed: test.status == 'PENDING' 
                      ? null 
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TestDetailScreen(test: test),
                            ),
                          );
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: test.status == 'PENDING' ? Colors.grey.shade300 : AppColors.primary,
                      foregroundColor: test.status == 'PENDING' ? Colors.grey.shade600 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      test.status == 'PENDING' 
                          ? 'SẮP MỞ'
                          : (test.progress == 0
                              ? context.tr('start_now')
                              : (test.progress < 100 ? context.tr('continue') : context.tr('practice_again'))),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
      case 'A1_A2':
        color = const Color(0xFF4CAF50);
        text = context.tr('a1_a2');
        break;
      case 'B1_B2':
        color = const Color(0xFFFF9800);
        text = context.tr('b1_b2');
        break;
      case 'C1':
        color = const Color(0xFFF44336);
        text = context.tr('c1');
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
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
            style: GoogleFonts.inter(
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

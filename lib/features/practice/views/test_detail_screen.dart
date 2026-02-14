import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/practice_viewmodel.dart';
import '../models/part_model.dart'; // Ensure PartModel is imported if needed separately, though test.parts has it
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../models/exam_model.dart';
import '../../../l10n/app_localizations.dart';
import 'test_simulation_screen.dart';

class TestDetailScreen extends StatefulWidget {
  final ExamModel test;

  const TestDetailScreen({super.key, required this.test});

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  Future<void> _checkHistoryAndStart(PartModel part) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
    final history = await viewModel.getPartHistory(part.id);

    // Hide loading
    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;

    if (history.isNotEmpty) {
      // Sort by date desc (first is latest) if not already
      // API returns sorted by attempt desc, providing latest first
      final latest = history.first;
      final score = latest['score'];
      final total = latest['totalQuestions'];
      final assessment = latest['aiAssessment'] ?? 'Hãy cố gắng hơn nhé!';

      final shouldRetake = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Bạn đã làm phần này rồi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bạn đã hoàn thành ${history.length} lần.'),
              const SizedBox(height: 8),
              const Text(
                'Kết quả gần nhất:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('$score/$total'),
              const SizedBox(height: 8),
              const Text(
                'Lời khuyên từ AI:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              Text(assessment),
              const SizedBox(height: 16),
              const Text('Bạn có muốn làm lại để cải thiện điểm số không?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Làm lại'),
            ),
          ],
        ),
      );

      if (shouldRetake != true) return;
    } else {
      // First time - Show Confirmation
      final duration = part.timeLimit != null
          ? '${part.timeLimit}'
          : 'Không giới hạn';

      final ready = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Bắt đầu làm bài?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bạn đã sẵn sàng để bắt đầu phần thi này chưa?'),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Thời gian: $duration',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (part.instructions != null)
                Text(
                  'Hướng dẫn: ${part.instructions}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Chưa'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Bắt đầu'),
            ),
          ],
        ),
      );

      if (ready != true) return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TestSimulationScreen(test: widget.test, partId: part.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.test.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Info Card
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    Icons.speed,
                    AppLocalizations.of(context)?.translate('difficulty') ??
                        'Độ khó',
                    _getDifficultyText(context, widget.test.difficulty),
                    _getDifficultyColor(widget.test.difficulty),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    Icons.timer_outlined,
                    AppLocalizations.of(context)?.translate('duration') ??
                        'Thời gian',
                    '${widget.test.duration} ${AppLocalizations.of(context)?.translate('minutes')}',
                    AppColors.textPrimary,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    Icons.format_list_numbered,
                    AppLocalizations.of(
                          context,
                        )?.translate('total_questions') ??
                        'Tổng số câu',
                    '${widget.test.totalQuestions}',
                    AppColors.textPrimary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Part List
            Text(
              AppLocalizations.of(context)?.translate('structure') ??
                  'Danh sách phần thi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            // ignore: unnecessary_to_list_in_spreads
            ...widget.test.parts.map(
              (part) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${part.partNumber}',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              part.partName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${part.totalQuestions} ${AppLocalizations.of(context)?.translate('questions') ?? 'câu'}',
                              style: GoogleFonts.poppins(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _checkHistoryAndStart(part),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Làm bài',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getDifficultyText(BuildContext context, String difficulty) {
    switch (difficulty) {
      case 'EASY':
        return AppLocalizations.of(context)?.translate('easy') ?? 'Dễ';
      case 'MEDIUM':
        return AppLocalizations.of(context)?.translate('medium') ??
            'Trung bình';
      case 'HARD':
        return AppLocalizations.of(context)?.translate('hard') ?? 'Khó';
      default:
        return difficulty;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'EASY':
        return const Color(0xFF4CAF50);
      case 'MEDIUM':
        return const Color(0xFFFF9800);
      case 'HARD':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }
}

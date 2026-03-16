import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/practice_viewmodel.dart';
import '../models/part_model.dart'; // Ensure PartModel is imported if needed separately, though test.parts has it
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../constants/app_constants.dart';
import '../models/exam_model.dart';
import '../../../l10n/app_localizations.dart';
import 'test_simulation_screen.dart';
import 'part1_simulation_screen.dart';
import 'reading_review_screen.dart';

class TestDetailScreen extends StatefulWidget {
  final ExamModel test;

  const TestDetailScreen({super.key, required this.test});

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  late ExamModel _test;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _test = widget.test;
    // Optionally verify latest data on init, but widget.test is usually fresh from PracticeScreen
    _refreshTest();
  }

  Future<void> _refreshTest() async {
    setState(() => _isLoading = true);
    try {
      final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
      final updatedTest = await viewModel.getTestById(widget.test.id);
      if (updatedTest != null && mounted) {
        setState(() {
          _test = updatedTest;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ignore: unused_element
  int _calculateTOEICScore(int correct, int total) {
    if (total == 0) return 5;
    double ratio = correct / total;
    int equivalentCorrect = (ratio * 100).round();
    int score = 0;
    if (equivalentCorrect <= 2) {
      score = 5;
    } else {
      score = 5 + (equivalentCorrect - 2) * 5;
    }
    if (score > 495) score = 495;
    return score;
  }

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

    // Colors consistent with TestSimulationScreen
    final Color adminDarkBlue = const Color(0xFF1E3A8A);
    final Color adminBlue = const Color(0xFF2563EB);
    final Color adminBgLight = const Color(0xFFF8FAFC);

    if (history.isNotEmpty) {
      final latest = history.first;
      final score = latest['score'];
      final total = latest['totalQuestions'];
      String assessment = 'Hãy cố gắng hơn nhé!';
      try {
        final rawAssessment = latest['aiAssessment'];
        if (rawAssessment != null && rawAssessment.isNotEmpty) {
          // Attempt to parse if it's a JSON string
          try {
            final parsed = jsonDecode(rawAssessment);
            if (parsed is Map<String, dynamic>) {
              // Use recommendationText for short advice, or fallback to assessment text (stripped of HTML if needed, but here we just take text)
              final aiFeedback =
                  parsed['shortFeedback'] ??
                  parsed['recommendationText'] ??
                  parsed['assessment'];

              if (aiFeedback != null) {
                assessment = aiFeedback
                    .toString()
                    .replaceAll('\\n', '\n')
                    .replaceAll('\\"', '"')
                    .replaceAll('\\t', '\t');
              } else {
                assessment =
                    'Hãy nhấn Xem lại để xem các nhận xét chi tiết hơn.';
              }
            } else {
              assessment = 'Vui lòng nhấn Xem lại để đọc đánh giá chi tiết.';
            }
          } catch (e) {
            // Not JSON, try simple regex extraction to avoid dumping raw JSON text to UI
            final match = RegExp(
              r'"shortFeedback"\s*:\s*"([^"]+)"',
            ).firstMatch(rawAssessment);
            if (match != null && match.groupCount >= 1) {
              assessment = match
                  .group(1)!
                  .replaceAll('\\n', '\n')
                  .replaceAll('\\"', '"')
                  .replaceAll('\\t', '\t');
            } else {
              assessment = 'Vui lòng nhấn Xem lại để đọc đánh giá chi tiết.';
            }
          }
        }
      } catch (_) {}

      final shouldRetake = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Force user to choose
        builder: (ctx) {
          final dialogScrollController = ScrollController();
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: adminDarkBlue.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.history_edu, size: 48, color: adminBlue),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn đã làm phần này rồi',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: adminDarkBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: (score as int) / (total as int),
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            score / total >= 0.8
                                ? const Color(0xFF4CAF50)
                                : (score / total >= 0.5
                                    ? const Color(0xFFFF9800)
                                    : const Color(0xFFF44336)),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${((score / total) * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: adminDarkBlue,
                            ),
                          ),
                          Text(
                            '$score/$total',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.psychology, size: 20, color: adminBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Lời khuyên từ AI:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: adminDarkBlue,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Scrollbar(
                      controller: dialogScrollController,
                      thumbVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(8),
                      child: SingleChildScrollView(
                        controller: dialogScrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: assessment.contains('<')
                              ? HtmlWidget(
                                  assessment,
                                  textStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                )
                              : Text(
                                  assessment,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: Colors.grey[700],
                          ),
                          child: const Text('Đóng'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: OutlinedButton(
                          onPressed: () async {
                            // Close dialog first
                            Navigator.of(ctx).pop();
                            
                            // Show loading while preparing data
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (c) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
                              
                              // 1. MUST load questions first to ensure state is ready
                              await viewModel.loadQuestions(part.id);
                              
                              if (!mounted) return;

                              // 2. Parse User Answers
                              Map<String, String> parsedUserAnswers = {};
                              try {
                                if (latest['answers'] != null) {
                                  final Map answersRaw = latest['answers'] is String 
                                      ? jsonDecode(latest['answers']) 
                                      : latest['answers'];
                                  answersRaw.forEach((k, v) {
                                    parsedUserAnswers[k.toString()] = v.toString();
                                  });
                                }
                              } catch (e) {
                                debugPrint("Error parsing historical answers: $e");
                              }

                              // 3. Parse AI Feedbacks
                              List<dynamic>? parsedAIFeedbacks;
                              try {
                                final rawAi = latest['aiAssessment'];
                                if (rawAi != null && rawAi.isNotEmpty) {
                                  final decoded = rawAi is String ? jsonDecode(rawAi) : rawAi;
                                  if (decoded is Map && decoded.containsKey('questionFeedbacks')) {
                                    parsedAIFeedbacks = decoded['questionFeedbacks'];
                                  }
                                }
                              } catch (e) {
                                debugPrint("Error parsing historical AI feedbacks: $e");
                              }

                              // Hide loading
                              if (mounted) Navigator.of(context).pop();

                              if (!mounted) return;

                              // 4. Navigation Logic based on Part Number
                              if (part.partNumber <= 4) {
                                // Listening Group
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Part1SimulationScreen(
                                      test: _test,
                                      partId: part.id,
                                      isReviewMode: true,
                                      initialUserAnswers: parsedUserAnswers,
                                      aiFeedbacks: parsedAIFeedbacks,
                                    ),
                                  ),
                                );
                              } else {
                                // Reading Group
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReadingReviewScreen(
                                      questions: viewModel.currentQuestions,
                                      userAnswers: parsedUserAnswers,
                                      partNumber: part.partNumber,
                                      aiFeedbacks: parsedAIFeedbacks,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Hide loading if error
                              if (mounted) Navigator.of(context).pop();
                              debugPrint("Error preparing review: $e");
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: adminBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: adminBlue,
                          ),
                          child: const Text('Xem lại'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: adminBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: Colors.white,
                            shadowColor: adminBlue.withValues(alpha: 0.4),
                          ),
                          child: const Text(
                            'Làm lại',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (shouldRetake != true) return;
    } else {
      // First time - Show Confirmation
      String durationStr = 'Không giới hạn';
      if (part.timeLimit != null) {
        final m = part.timeLimit! ~/ 60;
        final s = part.timeLimit! % 60;
        durationStr = s > 0 ? '$m phút $s giây' : '$m phút';
      }

      final ready = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: adminDarkBlue.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: adminBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 48,
                    color: adminBlue,
                  ),
                ), // Centered icon
                const SizedBox(height: 24),
                Text(
                  'Bắt đầu làm bài?',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: adminDarkBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn đã sẵn sàng để thử sức với phần thi này chưa?',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: adminBgLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: adminBlue.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, color: adminBlue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thời gian',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            durationStr,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: adminDarkBlue,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (part.instructions != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Hướng dẫn:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: adminDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50], // Lighter grey standard
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: HtmlWidget(
                          part.instructions!,
                          textStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.grey[700],
                        ),
                        child: const Text('Để sau'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: adminBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.white,
                          shadowColor: adminBlue.withValues(alpha: 0.4),
                        ),
                        child: const Text(
                          'Bắt đầu ngay',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (ready != true) return;
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (part.partNumber == 1) {
            return Part1SimulationScreen(test: _test, partId: part.id);
          }
          return TestSimulationScreen(test: _test, partId: part.id);
        },
      ),
    );
    // Refresh when coming back
    _refreshTest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _test.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
              ),
            if (_isLoading) const SizedBox(height: 8),
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
                    _getDifficultyText(context, _test.difficulty),
                    _getDifficultyColor(_test.difficulty),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    Icons.timer_outlined,
                    AppLocalizations.of(context)?.translate('duration') ??
                        'Thời gian',
                    '${_test.duration} ${AppLocalizations.of(context)?.translate('minutes')}',
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
                    '${_test.totalQuestions}',
                    AppColors.textPrimary,
                  ),
                ],
              ),
            ),

            // ignore: unnecessary_to_list_in_spreads
            ..._test.parts.map(
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
                          style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${part.totalQuestions} ${AppLocalizations.of(context)?.translate('questions') ?? 'câu'}',
                              style: GoogleFonts.inter(
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
                      if (part.userProgress != null && part.userProgress! > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  value: part.userProgress! / 100,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    part.userProgress! >= 80
                                        ? const Color(0xFF4CAF50) // Green
                                        : part.userProgress! >= 50
                                        ? const Color(0xFFFF9800) // Orange
                                        : const Color(0xFFF44336), // Red
                                  ),
                                  strokeWidth: 4,
                                ),
                              ),
                              Text(
                                '${part.userProgress}%',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
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
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontWeight: FontWeight.bold,
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

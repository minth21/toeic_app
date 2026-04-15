import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/practice_viewmodel.dart';
import '../models/part_model.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../constants/app_constants.dart';
import '../models/exam_model.dart';
import '../../../l10n/app_localizations.dart';
import 'test_simulation_screen.dart';
import 'part1_simulation_screen.dart';
import 'part2_simulation_screen.dart';
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
    final history = await viewModel.getPartHistory(part.id);

    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;

    final Color adminDarkBlue = const Color(0xFF1E3A8A);
    final Color adminBlue = const Color(0xFF2563EB);
    final Color adminBgLight = const Color(0xFFF8FAFC);

    final completedHistory = history.where((h) => h['score'] != null).toList();

    if (completedHistory.isNotEmpty) {
      final latest = completedHistory.first;
      final score = latest['score'];
      final total = latest['totalQuestions'];
      String assessment = 'Hãy cố gắng hơn nhé!';
      List<String> strengths = [];
      List<String> weaknesses = [];
      String shortFeedback = '';

      try {
        final rawAssessment = latest['aiAssessment'];
        if (rawAssessment != null && rawAssessment.isNotEmpty) {
          final dynamic parsed = rawAssessment is String ? jsonDecode(rawAssessment) : rawAssessment;
          if (parsed is Map<String, dynamic>) {
            final aiFeedback = parsed['shortFeedback'] ?? parsed['recommendationText'] ?? parsed['assessment'];
            shortFeedback = (parsed['shortFeedback'] ?? '').toString();
            
            if (aiFeedback != null) {
              assessment = aiFeedback.toString();
            }

            if (parsed['strengths'] is List) {
              strengths = (parsed['strengths'] as List).map((e) => e.toString()).toList();
            }
            if (parsed['weaknesses'] is List) {
              weaknesses = (parsed['weaknesses'] as List).map((e) => e.toString()).toList();
            }
          }
        }
      } catch (_) {}

      final shouldRetake = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: (total != null && total > 0) ? (score as num).toDouble() / (total as num).toDouble() : 0.0,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (total != null && total > 0 && (score as num) / (total as num) >= 0.8)
                                    ? const Color(0xFF4CAF50)
                                    : ((total != null && total > 0 && (score as num) / (total as num) >= 0.5)
                                        ? const Color(0xFFFF9800)
                                        : const Color(0xFFF44336)),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(total != null && total > 0) ? (((score as num) / (total as num)) * 100).toStringAsFixed(0) : 0}%',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: adminDarkBlue,
                                ),
                              ),
                              Text(
                                '${score ?? 0}/${total ?? 0}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // NEW: Strengths and Weaknesses
                  if (strengths.isNotEmpty || weaknesses.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (strengths.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ĐIỂM MẠNH',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green[700], letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 8),
                                ...strengths.take(2).map((s) => Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green[100]!)),
                                  child: Text(s, style: GoogleFonts.inter(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                )),
                              ],
                            ),
                          ),
                        if (strengths.isNotEmpty && weaknesses.isNotEmpty) const SizedBox(width: 12),
                        if (weaknesses.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CẦN CẢI THIỆN',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange[700], letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 8),
                                ...weaknesses.take(2).map((w) => Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange[100]!)),
                                  child: Text(w, style: GoogleFonts.inter(fontSize: 11, color: Colors.orange[800], fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                )),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // NEW: Styled AI Assessment Card
                  Text(
                    'NHẬN XÉT TỪ AI',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: adminBlue, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: adminBlue.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (shortFeedback.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  shortFeedback,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF312E81),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Color(0xFFE0E7FF), thickness: 1),
                          ),
                        ],
                        Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: RawScrollbar(
                            thumbColor: adminBlue.withValues(alpha: 0.2),
                            radius: const Radius.circular(8),
                            thickness: 4,
                            child: SingleChildScrollView(
                              child: assessment.contains('<')
                                  ? HtmlWidget(
                                      assessment,
                                      textStyle: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF374151),
                                        height: 1.6,
                                      ),
                                    )
                                  : Text(
                                      assessment,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF374151),
                                        height: 1.6,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
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
                            Navigator.of(ctx).pop();
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (c) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
                              await viewModel.loadQuestions(part.id);
                              if (!mounted) return;

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

                              if (mounted) Navigator.of(context).pop();
                              if (!mounted) return;

                              if (part.partNumber == 2) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Part2SimulationScreen(
                                      questions: viewModel.currentQuestions,
                                      partAudioUrl: part.audioUrl,
                                      isReviewMode: true,
                                      userAnswers: parsedUserAnswers,
                                      aiFeedbacks: parsedAIFeedbacks,
                                      overallFeedback: latest['assessment'] ?? latest['aiAnalysis'] ?? latest['aiAssessment'],
                                    ),
                                  ),
                                );
                              } else if (part.partNumber <= 4) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Part1SimulationScreen(
                                      test: _test,
                                      partId: part.id,
                                      isReviewMode: true,
                                      initialUserAnswers: parsedUserAnswers,
                                      aiFeedbacks: parsedAIFeedbacks,
                                      overallFeedback: latest['assessment'] ?? latest['aiAnalysis'] ?? latest['aiAssessment'],
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReadingReviewScreen(
                                      questions: viewModel.currentQuestions,
                                      userAnswers: parsedUserAnswers,
                                      partNumber: part.partNumber,
                                      aiFeedbacks: parsedAIFeedbacks,
                                      overallFeedback: latest['assessment'] ?? latest['aiAnalysis'] ?? latest['aiAssessment'],
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
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
                ),
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
                      color: Colors.grey[50], 
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
          if (part.partNumber == 2) {
            return Part2SimulationScreen(
              questions: viewModel.currentQuestions,
              partAudioUrl: part.audioUrl,
              part: part,
            );
          }
          return TestSimulationScreen(test: _test, partId: part.id);
        },
      ),
    );

    _refreshTest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            bottom: _isLoading
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : null,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.premiumGradient,
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: CircleAvatar(
                      radius: 120,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -30,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 70),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _test.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.premiumShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem(
                    icon: Icons.speed,
                    label: AppLocalizations.of(context)?.translate('difficulty') ??
                        'Độ khó',
                    value: _getDifficultyText(context, _test.difficulty),
                    color: _getDifficultyColor(_test.difficulty),
                  ),
                  _buildVerticalDivider(),
                  _buildSummaryItem(
                    icon: Icons.timer_outlined,
                    label:
                        AppLocalizations.of(context)?.translate('duration') ?? 'Thời gian',
                    value: '${_test.duration}ph',
                    color: AppColors.primary,
                  ),
                  _buildVerticalDivider(),
                  _buildSummaryItem(
                    icon: Icons.format_list_numbered,
                    label: AppLocalizations.of(context)?.translate('total_questions') ??
                        'Tổng câu',
                    value: '${_test.totalQuestions}',
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                   Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cấu trúc đề thi',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final part = _test.parts[index];
                  return _buildPartCard(part);
                },
                childCount: _test.parts.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider.withValues(alpha: 0.5),
    );
  }

  Widget _buildPartCard(PartModel part) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _checkHistoryAndStart(part),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.indigo50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${part.partNumber}',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              part.partName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (part.instructions != null && part.instructions!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showInstructionsDialog(part),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.help_outline, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            '${part.totalQuestions} câu hỏi',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (part.userProgress != null && part.userProgress! > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: CircularProgressIndicator(
                            value: part.userProgress! / 100,
                            backgroundColor: AppColors.indigo50,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              part.userProgress! >= 80
                                  ? AppColors.success
                                  : (part.userProgress! >= 50
                                      ? AppColors.warning
                                      : AppColors.error),
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        Text(
                          '${part.userProgress}%',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (part.userProgress != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPartActionButton(
                        icon: Icons.history_rounded,
                        label: 'Xem lại',
                        onTap: () => _directReview(part),
                        isPrimary: false,
                      ),
                      const SizedBox(width: 4),
                      _buildPartActionButton(
                        icon: Icons.refresh_rounded,
                        label: 'Làm lại',
                        onTap: () => _directRetake(part),
                        isPrimary: true,
                      ),
                    ],
                  )
                else
                  const Icon(Icons.play_circle_filled_rounded,
                      color: AppColors.primary, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDifficultyText(BuildContext context, String difficulty) {
    switch (difficulty) {
      case 'A1_A2':
        return AppLocalizations.of(context)?.translate('a1_a2') ?? 'A1-A2';
      case 'B1_B2':
        return AppLocalizations.of(context)?.translate('b1_b2') ?? 'B1-B2';
      case 'C1':
        return AppLocalizations.of(context)?.translate('c1') ?? 'C1';
      default:
        return difficulty;
    }
  }

  Widget _buildPartActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.indigo50,
          borderRadius: BorderRadius.circular(10),
          border: isPrimary ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstructionsDialog(PartModel part) {
    if (part.instructions == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Hướng dẫn: ${part.partName}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: HtmlWidget(
                    part.instructions!,
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _directReview(PartModel part) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
    final history = await viewModel.getPartHistory(part.id);
    
    if (mounted) Navigator.pop(context); // Close loading
    if (history.isEmpty) return;

    final latest = history.first;
    await viewModel.loadQuestions(part.id);
    
    if (!mounted) return;

    Map<String, String> parsedUserAnswers = {};
    if (latest['answers'] != null) {
      final Map answersRaw = latest['answers'] is String ? jsonDecode(latest['answers']) : latest['answers'];
      answersRaw.forEach((k, v) => parsedUserAnswers[k.toString()] = v.toString());
    }

    List<dynamic>? parsedAIFeedbacks;
    final rawAi = latest['aiAssessment'];
    if (rawAi != null && rawAi.isNotEmpty) {
      final decoded = rawAi is String ? jsonDecode(rawAi) : rawAi;
      if (decoded is Map && decoded.containsKey('questionFeedbacks')) {
        parsedAIFeedbacks = decoded['questionFeedbacks'];
      }
    }

    if (part.partNumber <= 4) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => Part1SimulationScreen(
          test: _test,
          partId: part.id,
          isReviewMode: true,
          initialUserAnswers: parsedUserAnswers,
          aiFeedbacks: parsedAIFeedbacks,
        ),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ReadingReviewScreen(
          questions: viewModel.currentQuestions,
          userAnswers: parsedUserAnswers,
          partNumber: part.partNumber,
          aiFeedbacks: parsedAIFeedbacks,
        ),
      ));
    }
  }

  void _directRetake(PartModel part) {
    if (part.partNumber == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Part1SimulationScreen(test: _test, partId: part.id)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => TestSimulationScreen(test: _test, partId: part.id)));
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'A1_A2':
        return const Color(0xFF4CAF50);
      case 'B1_B2':
        return const Color(0xFFFF9800);
      case 'C1':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }
}

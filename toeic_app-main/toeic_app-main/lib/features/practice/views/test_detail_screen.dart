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
  bool _isProcessing = false;

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

  void _showLoadingDialog(BuildContext context, {String message = 'Đang chuẩn bị dữ liệu...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkHistoryAndStart(PartModel part) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    final viewModel = Provider.of<PracticeViewModel>(context, listen: false);

    try {
      final history = await viewModel.getPartHistory(part.id);
      
      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      if (history.isNotEmpty) {
        final latest = history.first;
        final score = latest['score'];
        final total = latest['totalQuestions'];
        String assessment = 'Hãy cố gắng hơn nhé!';
        List<String> strengths = [];
        List<String> weaknesses = [];
        String shortFeedback = '';

        try {
          final rawAssessment = latest['aiAssessment'];
          if (rawAssessment != null && rawAssessment.isNotEmpty) {
            final dynamic parsed = rawAssessment is String
                ? jsonDecode(rawAssessment)
                : rawAssessment;
            if (parsed is Map<String, dynamic>) {
              final aiFeedback =
                  parsed['shortFeedback'] ??
                  parsed['recommendationText'] ??
                  parsed['assessment'];
              shortFeedback = (parsed['shortFeedback'] ?? '').toString();

              if (aiFeedback != null) {
                assessment = aiFeedback.toString();
              }

              if (parsed['strengths'] is List) {
                strengths = (parsed['strengths'] as List)
                    .map((e) => e.toString())
                    .toList();
              }
              if (parsed['weaknesses'] is List) {
                weaknesses = (parsed['weaknesses'] as List)
                    .map((e) => e.toString())
                    .toList();
              }
            }
          }
        } catch (_) {}

        final bool? ready = await showDialog<bool>(
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
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.history_edu, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Bạn đã làm phần này rồi',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
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
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: (total != null && total > 0)
                                    ? (score ?? 0).toDouble() /
                                        (total ?? 0).toDouble()
                                    : 0.0,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey[100],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  (total != null &&
                                          total > 0 &&
                                          (score ?? 0) / (total ?? 0) >= 0.8)
                                      ? AppColors.success
                                      : ((total != null &&
                                              total > 0 &&
                                              (score ?? 0) / (total ?? 0) >= 0.5)
                                          ? AppColors.warning
                                          : AppColors.error),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${score ?? 0}/${total ?? 0}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Đúng',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Strengths/Weaknesses
                    if (strengths.isNotEmpty || weaknesses.isNotEmpty) ...[
                      Row(
                        children: [
                          if (strengths.isNotEmpty)
                            Expanded(child: _buildCompactTagList('Điểm mạnh', strengths, Colors.green)),
                          if (strengths.isNotEmpty && weaknesses.isNotEmpty) const SizedBox(width: 8),
                          if (weaknesses.isNotEmpty)
                            Expanded(child: _buildCompactTagList('Cần cải thiện', weaknesses, Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // AI Assessment
                    if (assessment.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.indigo50.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NHẬN XÉT AI', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary)),
                            const SizedBox(height: 4),
                            Text(
                              shortFeedback.isNotEmpty ? shortFeedback : 'Bạn đang có tiến bộ tốt!',
                              style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Đóng'))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _directReview(part);
                            }, 
                            child: const Text('Xem lại')
                          )
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true), 
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            child: const Text('Làm bài')
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (ready == true) {
          await _directSimulation(part);
        }
      } else {
        await _directSimulation(part);
      }
    } catch (e) {
      debugPrint("Error in _checkHistoryAndStart: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _directSimulation(PartModel part) async {
    _showLoadingDialog(context, message: 'Đang chuẩn bị bài thi...');
    
    try {
      final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
      await viewModel.loadQuestions(part.id);

      if (!mounted) return;
      Navigator.pop(context);

      if (viewModel.currentQuestions.isEmpty) {
        debugPrint('[Integrity Audit] WARNING: Questions list is empty for part ${part.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tải được câu hỏi. Có thể dữ liệu chưa sẵn sàng.')),
          );
        }
        return;
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
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error starting simulation: $e");
    }
  }

  Future<void> _directReview(PartModel part) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    _showLoadingDialog(context, message: 'Đang tải lịch sử...');

    try {
      final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
      final history = await viewModel.getPartHistory(part.id);

      if (mounted) Navigator.pop(context);

      if (history.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final latestAttempt = history.first;
      
      // NEW: Fetch FULL detail for the attempt to get correct/incorrect flags
      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }
      _showLoadingDialog(context, message: 'Đang tải chi tiết kết quả...');
      final detailedAttempt = await viewModel.loadAttemptDetail(latestAttempt['id'].toString());
      if (mounted) Navigator.of(context).pop(); // Close loading

      if (detailedAttempt == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải chi tiết bài làm.')),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Loading questions
      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }
      _showLoadingDialog(context, message: 'Đang chuẩn bị bản xem lại...');
      await viewModel.loadQuestions(part.id);
      if (mounted) Navigator.pop(context); // Close loading
      
      if (viewModel.currentQuestions.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể tải dữ liệu câu hỏi.')),
            );
          }
          setState(() => _isProcessing = false);
          return;
      }

      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      Map<String, String> parsedUserAnswers = {};
      final answersData = detailedAttempt['answers'];
      if (answersData != null) {
        final Map answersRaw = answersData is String
            ? jsonDecode(answersData)
            : answersData;
        answersRaw.forEach(
          (k, v) => parsedUserAnswers[k.toString()] = v.toString(),
        );
      }

      List<dynamic>? parsedAIFeedbacks;
      final rawAi = detailedAttempt['aiAssessment'] ?? detailedAttempt['aiAnalysis'];
      if (rawAi != null && rawAi.isNotEmpty) {
        final decoded = rawAi is String ? jsonDecode(rawAi) : rawAi;
        if (decoded is Map && decoded.containsKey('questionFeedbacks')) {
          parsedAIFeedbacks = decoded['questionFeedbacks'];
        }
      }

      if (part.partNumber <= 4) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Part1SimulationScreen(
              test: _test,
              partId: part.id,
              isReviewMode: true,
              initialUserAnswers: parsedUserAnswers,
              aiFeedbacks: parsedAIFeedbacks,
              overallFeedback:
                  detailedAttempt['assessment'] ??
                  detailedAttempt['aiAnalysis'] ??
                  detailedAttempt['aiAssessment'],
              part: part,
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
              correctQuestionIds: _extractCorrectIds(detailedAttempt),
              partNumber: part.partNumber,
              aiFeedbacks: parsedAIFeedbacks,
              overallFeedback:
                  detailedAttempt['assessment'] ??
                  detailedAttempt['aiAnalysis'] ??
                  detailedAttempt['aiAssessment'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error in _directReview: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Set<String> _extractCorrectIds(dynamic attempt) {
    final List<dynamic> details = attempt?['details'] ?? [];
    return details
        .where((d) => d['isCorrect'] == true || d['is_correct'] == true)
        .map((d) {
          final qMap = d['question'] as Map?;
          return (d['questionId'] ?? d['question_id'] ?? qMap?['id'] ?? '').toString();
        })
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _directRetake(PartModel part) async {
    if (_isProcessing) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Text(
              'Làm lại bài thi?',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Bạn đã hoàn thành phần thi này. Bạn có chắc chắn muốn làm lại để cải thiện điểm số không? Lịch sử cũ của bạn vẫn sẽ được lưu lại.',
          style: GoogleFonts.inter(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Bắt đầu lại',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await _directSimulation(part);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Colors.white,
              ),
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
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
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
                          _test.title.isNotEmpty ? _test.title : 'Unknown Test',
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
                    label: context.tr('difficulty'),
                    value: _getDifficultyText(context, _test.difficulty),
                    color: _getDifficultyColor(_test.difficulty),
                  ),
                  _buildVerticalDivider(),
                  _buildSummaryItem(
                    icon: Icons.timer_outlined,
                    label: context.tr('duration'),
                    value: '${_test.duration}ph',
                    color: AppColors.primary,
                  ),
                  _buildVerticalDivider(),
                  _buildSummaryItem(
                    icon: Icons.format_list_numbered,
                    label: context.tr('total_questions'),
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
              delegate: SliverChildBuilderDelegate((context, index) {
                final part = _test.parts[index];
                return _buildPartCard(part);
              }, childCount: _test.parts.length),
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
    final status = part.status.isNotEmpty ? part.status : 'ACTIVE';
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
          onTap: status == 'PENDING' ? null : () => _checkHistoryAndStart(part),
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
                              part.partName.isNotEmpty ? part.partName : 'Unknown Part',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (status == 'PENDING') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'CHƯA DUYỆT',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                          if (part.instructions != null &&
                              part.instructions!.isNotEmpty) ...[
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
                          Icon(
                            Icons.help_outline,
                            size: 14,
                            color: AppColors.textHint,
                          ),
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
                            value: (part.userProgress ?? 0) / 100,
                            backgroundColor: AppColors.indigo50,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              (part.userProgress ?? 0) >= 80
                                  ? AppColors.success
                                  : ((part.userProgress ?? 0) >= 50
                                        ? AppColors.warning
                                        : AppColors.error),
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        Text(
                          '${part.userProgress ?? 0}%',
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
                        label: 'Làm bài',
                        onTap: () => _directRetake(part),
                        isPrimary: true,
                      ),
                    ],
                  )
                else if (status == 'PENDING')
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_clock_rounded,
                        color: Colors.grey,
                        size: 24,
                      ),
                      Text(
                        'Chưa mở',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(
                    Icons.play_circle_filled_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDifficultyText(BuildContext context, String difficulty) {
    if (difficulty.isEmpty) return 'B1-B2';
    
    switch (difficulty.toUpperCase()) {
      case 'A1_A2':
        return context.tr('a1_a2');
      case 'B1_B2':
        return context.tr('b1_b2');
      case 'C1':
        return context.tr('c1');
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
          border: isPrimary
              ? null
              : Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
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
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                  ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'A1_A2':
        return AppColors.success;
      case 'B1_B2':
        return AppColors.warning;
      case 'C1':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCompactTagList(String label, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: color.withValues(alpha: 0.8))),
        const SizedBox(height: 4),
        ...items.take(2).map((item) => Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(item,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: color, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            )),
      ],
    );
  }
}

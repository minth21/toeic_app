import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/practice_viewmodel.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../views/class_feedback_screen.dart';
import '../models/part_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_typography.dart';
import '../models/exam_model.dart';
import '../../../l10n/app_localizations.dart';
import 'test_simulation_screen.dart';
import 'part1_simulation_screen.dart';
import 'part2_simulation_screen.dart';
import 'reading_review_screen.dart';
import 'listening_simulation_screen.dart';

class TestDetailScreen extends StatefulWidget {
  final ExamModel? test;
  final String? testId;

  const TestDetailScreen({super.key, this.test, this.testId})
      : assert(test != null || testId != null);

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
    if (widget.test != null) {
      _test = widget.test!;
    } else {
      // Skeleton test while loading
      _test = ExamModel(
        id: widget.testId!,
        title: 'Đang tải...',
        difficulty: '...',
        duration: 0,
        totalQuestions: 0,
        listeningQuestions: 0,
        readingQuestions: 0,
      );
    }
    _refreshTest();
  }

  Future<void> _refreshTest() async {
    setState(() => _isLoading = true);
    try {
      final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
      await viewModel.loadHistory(); // Ensure history is fresh
      final updatedTest = await viewModel.getTestById(_test.id);
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

      int? score;
      int? total;
      String assessment = 'Hãy cố gắng hơn nhé!';
      List<String> strengths = [];
      List<String> weaknesses = [];

      if (history.isNotEmpty) {
        final latest = history.first;
        score = latest['score'] ?? latest['correctCount'];
        total = latest['totalQuestions'] ?? latest['total'];

        try {
          final rawAssessment = latest['aiAssessment'];
          if (rawAssessment != null && rawAssessment.isNotEmpty) {
            String cleanJson = rawAssessment is String ? rawAssessment : '';
            if (rawAssessment is String && rawAssessment.contains('```')) {
              cleanJson = rawAssessment
                  .replaceFirst(RegExp(r'```json'), '')
                  .replaceFirst(RegExp(r'```'), '')
                  .trim();
            }
            
            final dynamic parsed = rawAssessment is String
                ? jsonDecode(cleanJson.isNotEmpty ? cleanJson : rawAssessment)
                : rawAssessment;
            if (parsed is Map<String, dynamic>) {
              final aiFeedback =
                  parsed['shortFeedback'] ??
                  parsed['recommendationText'] ??
                  parsed['assessment'];

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
      }

      final bool? ready = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final instructionText = part.instructions ?? _getStandardInstructions(part.partNumber);
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header Section with Gradient ---
                    Stack(
                      children: [
                        Container(
                          height: 120,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            _getPartIcon(part.partNumber),
                            size: 140,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!part.partName.toUpperCase().contains('PART'))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'PART ${part.partNumber}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                part.partName,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                        ),
                      ],
                    ),

                    // --- Scrollable Body Section ---
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mission Details
                            Row(
                              children: [
                                _buildMissionSticker(Icons.help_outline_rounded, '${part.totalQuestions} câu hỏi'),
                                const SizedBox(width: 12),
                                _buildMissionSticker(Icons.timer_outlined, part.timeLimit != null ? '${part.timeLimit! ~/ 60} phút' : 'Tự do'),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Instructions Section
                            Text(
                              'HƯỚNG DẪN NHIỆM VỤ',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF64748B),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: HtmlWidget(
                                instructionText,
                                textStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: const Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            if (part.instructionImgUrl != null && part.instructionImgUrl!.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AppConstants.getFullUrl(part.instructionImgUrl).isEmpty
                                    ? const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey))
                                    : Image.network(
                                        AppConstants.getFullUrl(part.instructionImgUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Container(
                                          height: 100,
                                          width: double.infinity,
                                          color: Colors.grey.shade100,
                                          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                        ),
                                      ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Previous Best (If history exists)
                            if (history.isNotEmpty) ...[
                              Text(
                                'THÀNH TÍCH TRƯỚC ĐÓ',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF64748B),
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAuraHistoryCard(score, total, assessment, strengths, weaknesses),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // --- Fixed Buttons Section ---
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (history.isNotEmpty)
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _directReview(part);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Icon(Icons.history_rounded, color: Color(0xFF64748B)),
                              ),
                            ),
                          if (history.isNotEmpty) const SizedBox(width: 12),
                          Expanded(
                            flex: 5,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                history.isEmpty ? 'BẮT ĐẦU NGAY' : 'LÀM LẠI',
                                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (ready == true) {
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
            if (part.partNumber == 3 || part.partNumber == 4) {
              return ListeningSimulationScreen(test: _test, partId: part.id, part: part);
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
        if (part.partNumber == 3 || part.partNumber == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListeningSimulationScreen(
                test: _test,
                partId: part.id,
                isReviewMode: true,
                initialUserAnswers: parsedUserAnswers,
                part: part,
              ),
            ),
          );
        } else {
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
        }
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

          // --- TEACHER'S OPINION SECTION ---
          _buildTeacherOpinionSliver(),

          // --- ASK TEACHER ACTION ---
          _buildAskTeacherSliver(),

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
                    'Cấu trúc đề ôn luyện',
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getPartIcon(part.partNumber),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'PART ${part.partNumber}: ${part.partName.toUpperCase().replaceFirst('PART ${part.partNumber}:', '').replaceFirst('PART ${part.partNumber}', '').trim()}',
                              style: AppTypography.ui(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: const Color(0xFF1E3A8A), // Dark Blue for Premium feel
                                letterSpacing: 0.2,
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
                                style: AppTypography.ui(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.help_outline_rounded,
                                size: 14,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${part.totalQuestions} câu hỏi',
                                style: AppTypography.ui(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (part.instructions != null && part.instructions!.isNotEmpty)
                            GestureDetector(
                              onTap: () => _showInstructionsDialog(part),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Hướng dẫn',
                                    style: AppTypography.ui(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
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
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
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
                      ),
                    ),
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
                  Expanded(
                    child: Text(
                      'Hướng dẫn: ${part.partName}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  String _getStandardInstructions(int partNumber) {
    switch (partNumber) {
      case 1: return "Phần 1: Mô tả hình ảnh. Với mỗi câu hỏi, bạn sẽ nghe 4 câu mô tả về một bức tranh. Hãy chọn câu mô tả đúng nhất những gì bạn thấy trong tranh.";
      case 2: return "Phần 2: Hỏi - Đáp. Bạn sẽ nghe một câu hỏi hoặc một câu nói và 3 lựa chọn trả lời. Hãy chọn câu trả lời phù hợp nhất cho câu hỏi đó.";
      case 3: return "Phần 3: Đoạn hội thoại. Bạn sẽ nghe các đoạn hội thoại giữa hai hoặc nhiều người. Với mỗi đoạn, hãy trả lời 3 câu hỏi liên quan.";
      case 4: return "Phần 4: Bài nói ngắn. Bạn sẽ nghe các bài nói ngắn do một người trình bày. Với mỗi bài, hãy trả lời 3 câu hỏi liên quan.";
      case 5: return "Phần 5: Hoàn thành câu. Hãy chọn từ hoặc cụm từ phù hợp nhất để hoàn thành câu văn đã cho.";
      case 6: return "Phần 6: Hoàn thành đoạn văn. Hãy chọn từ, cụm từ hoặc câu văn phù hợp nhất để điền vào các khoảng trống trong đoạn văn.";
      case 7: return "Phần 7: Đọc hiểu. Hãy đọc các đoạn văn (đơn hoặc đa) và trả lời các câu hỏi dựa trên thông tin đã đọc.";
      default: return "Hãy chọn đáp án đúng nhất cho mỗi câu hỏi.";
    }
  }

  IconData _getPartIcon(int partNumber) {
    switch (partNumber) {
      case 1: return Icons.camera_alt_rounded;
      case 2: return Icons.question_answer_rounded;
      case 3: return Icons.forum_rounded;
      case 4: return Icons.record_voice_over_rounded;
      case 5: return Icons.edit_note_rounded;
      case 6: return Icons.article_rounded;
      case 7: return Icons.menu_book_rounded;
      default: return Icons.assignment_rounded;
    }
  }

  Widget _buildMissionSticker(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuraHistoryCard(int? score, int? total, String assessment, List<String> strengths, List<String> weaknesses) {
    final double percentage = (total != null && total > 0) ? (score ?? 0) / total : 0;
    final color = percentage >= 0.8 ? Colors.green : (percentage >= 0.5 ? Colors.orange : Colors.red);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      value: percentage,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeWidth: 5,
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết quả: ${score ?? 0}/${total ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nhận xét AI: $assessment',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (strengths.isNotEmpty || weaknesses.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (strengths.isNotEmpty)
              _buildCompactBadgeRow('Ưu điểm', strengths, Colors.green),
            if (weaknesses.isNotEmpty)
              _buildCompactBadgeRow('Cần cải thiện', weaknesses, Colors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactBadgeRow(String title, List<String> items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          Expanded(
            child: Text(
              items.join(', '),
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTeacherOpinionSliver() {
    final viewModel = context.watch<PracticeViewModel>();
    final history = viewModel.history;
    
    // Find the latest attempt for THIS specific test
    final latestTestAttempt = history.where((h) => h['testId'] == _test.id).toList();
    
    if (latestTestAttempt.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    final latest = latestTestAttempt.first;
    final String? teacherNote = latest['teacherNote'];
    
    if (teacherNote == null || teacherNote.trim().isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ý KIẾN GIÁO VIÊN',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              teacherNote,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '— Phản hồi cho bài làm của bạn',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClassFeedbackScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: const Text('Hỏi giáo viên'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAskTeacherSliver() {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user?.classId == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // Only show if teacherNote is NOT already shown to avoid duplication
    final viewModel = context.watch<PracticeViewModel>();
    final history = viewModel.history;
    final latestTestAttempt = history.where((h) => h['testId'] == _test.id).toList();
    if (latestTestAttempt.isNotEmpty && latestTestAttempt.first['teacherNote'] != null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ClassFeedbackScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bạn có thắc mắc về đề ôn luyện này?',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Nhấn để gửi câu hỏi cho giáo viên của bạn',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam_model.dart';
import '../models/part_model.dart';
import '../models/question_model.dart';
import '../viewmodels/practice_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import 'widgets/custom_audio_player.dart';
import 'widgets/touchable_passage_widget.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'practice_result_screen.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import 'class_feedback_screen.dart';

class Part1SimulationScreen extends StatefulWidget {
  final ExamModel test;
  final String? partId;
  final bool isReviewMode;
  final Map<String, String>? initialUserAnswers;
  final PartModel? part;
  final List<dynamic>? aiFeedbacks;
  final String? overallFeedback;

  const Part1SimulationScreen({
    super.key,
    required this.test,
    this.partId,
    this.isReviewMode = false,
    this.initialUserAnswers,
    this.part,
    this.aiFeedbacks,
    this.overallFeedback,
  });

  @override
  State<Part1SimulationScreen> createState() => _Part1SimulationScreenState();
}

class _Part1SimulationScreenState extends State<Part1SimulationScreen> {
  bool _showInstruction = true;
  PartModel? _selectedPart;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final Map<String, String> _userAnswers = {};
  final Set<String> _flaggedQuestions = {};
  bool _isSubmitted = false;

  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isTimed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isReviewMode) {
      _isSubmitted = true;
      _showInstruction = false;
      if (widget.initialUserAnswers != null) {
        _userAnswers.addAll(widget.initialUserAnswers!);
      }
    }

    if (widget.partId != null) {
      try {
        _selectedPart = widget.test.parts.firstWhere(
          (p) => p.id == widget.partId,
        );
      } catch (e) {
        debugPrint("Part not found: $e");
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PracticeViewModel>().loadQuestions(widget.partId!);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isSubmitted && !_isTimed && _selectedPart?.timeLimit != null) {
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    if (_selectedPart!.timeLimit != null && _selectedPart!.timeLimit! > 0) {
      setState(() {
        _remainingTime = Duration(seconds: _selectedPart!.timeLimit!);
        _isTimed = true;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
        _submitTest();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Hết giờ làm bài!')));
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _onOptionSelected(String questionId, String option) {
    if (_isSubmitted) return;
    setState(() {
      _userAnswers[questionId] = option;
    });
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    final viewModel = context.read<PracticeViewModel>();
    final questions = viewModel.currentQuestions;

    int correctCount = 0;
    for (int i = 0; i < questions.length; i++) {
      if (_userAnswers[questions[i].id] == questions[i].correctAnswer) {
        correctCount++;
      }
    }

    setState(() {
      _isSubmitted = true;
    });

    // ── Gọi API submit để backend lưu kết quả + trigger AI assessment ──
    String attemptId = '0';
    try {
      if (_selectedPart != null) {
        final result = await viewModel.submitPart(
          _selectedPart!.id,
          Map<String, String>.from(_userAnswers),
          timeTaken: _isTimed
              ? (_selectedPart!.timeLimit ?? 0) - _remainingTime.inSeconds
              : null,
        );
        if (result != null) {
          attemptId =
              result['attemptId']?.toString() ??
              result['id']?.toString() ??
              '0';
          debugPrint('[Part1] Submit success, attemptId: $attemptId');
        }
      }
    } catch (e) {
      debugPrint('[Part1] Submit error: $e');
    }

    if (!mounted) return;

    // Navigate to Result Screen (Unified flow)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeResultScreen(
          resultData: {
            'score': correctCount,
            'totalQuestions': questions.length,
            'userAnswers': _userAnswers,
          },
          part: _selectedPart!,
          attemptId: attemptId,
          fromSimulation: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleFlag(String qId) {
    setState(() {
      if (_flaggedQuestions.contains(qId)) {
        _flaggedQuestions.remove(qId);
      } else {
        _flaggedQuestions.add(qId);
      }
    });
  }

  // ── Palette Helpers ───────────────────────────────────────────────────────

  // Xác định màu palette cho từng ô câu hỏi.
  // Khi ở chế độ Review (_isSubmitted = true): phân biệt Đúng/Sai.
  // Khi đang thi: chỉ phân biệt Đang xem / Chưa trả lời.
  Map<String, dynamic> _getPaletteColorInfo(
    int i,
    List<QuestionModel> questions,
  ) {
    final qId = questions[i].id;
    final bool isActive = i == _currentIndex;
    final bool isFlagged = _flaggedQuestions.contains(qId);
    final String? userAnswer = _userAnswers[qId];
    final bool isAnswered = userAnswer != null && userAnswer.isNotEmpty;

    // Default
    Map<String, dynamic> info = {
      'bg': Colors.white,
      'border': AppColors.divider,
      'text': AppColors.textSecondary,
      'shadow': false,
      'borderWidth': 1.5,
    };

    // 1. Result mode - Prioritize Correct/Incorrect if submitted
    if (_isSubmitted && isAnswered) {
      final bool isCorrect = userAnswer == questions[i].correctAnswer;
      if (isCorrect) {
        info['bg'] = const Color(0xFF10B981);
        info['border'] = const Color(0xFF059669);
        info['text'] = Colors.white;
      } else {
        info['bg'] = const Color(0xFFEF4444);
        info['border'] = const Color(0xFFDC2626);
        info['text'] = Colors.white;
      }
    } else if (isAnswered && !_isSubmitted) {
      // Only show "Answered" purple base if NOT submitted
      info['bg'] = AppColors.primary;
      info['border'] = const Color(0xFF1E3A8A);
      info['text'] = Colors.white;
    }

    // 2. Flag override (Show flag color if not submitted OR overwrite if flagged)
    if (isFlagged && !_isSubmitted) {
      info['bg'] = const Color(0xFFF59E0B);
      info['border'] = const Color(0xFFD97706);
      info['text'] = Colors.white;
    }

    // 3. Current indicator
    if (isActive) {
      info['border'] = _isSubmitted ? (info['text'] == Colors.white ? Colors.white : AppColors.primary) : AppColors.primary;
      info['borderWidth'] = 3.5;
      info['shadow'] = true;
      if (info['bg'] == Colors.white) {
        info['bg'] = AppColors.indigo50;
        info['text'] = AppColors.primary;
      }
    }

    return info;
  }

  void _showQuestionGrid(BuildContext context, List<QuestionModel> questions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Tiêu đề
              Text(
                'Bảng câu hỏi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Chú thích màu (Legend)
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildPaletteLegendItem(
                    const Color(0xFFF59E0B),
                    const Color(0xFFD97706),
                    'Cắm cờ',
                  ),
                  if (_isSubmitted) ...[
                    _buildPaletteLegendItem(
                      const Color(0xFF10B981),
                      const Color(0xFF059669),
                      'Đúng',
                    ),
                    _buildPaletteLegendItem(
                      const Color(0xFFEF4444),
                      const Color(0xFFDC2626),
                      'Sai',
                    ),
                  ],
                  _buildPaletteLegendItem(
                    Colors.white,
                    AppColors.divider,
                    'Chưa trả lời',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Grid câu hỏi
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: questions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, i) {
                    final colorInfo = _getPaletteColorInfo(i, questions);
                    final isFlagged = _flaggedQuestions.contains(questions[i].id);

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: colorInfo['bg'],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorInfo['border'],
                            width: colorInfo['borderWidth'] ?? 1.5,
                          ),
                          boxShadow: colorInfo['shadow'] == true
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: colorInfo['text'],
                              ),
                            ),
                            if (isFlagged)
                              Positioned(
                                top: 3,
                                right: 3,
                                child: Icon(
                                  Icons.flag_rounded,
                                  size: 9,
                                  color: colorInfo['text'] == Colors.white ? Colors.white : AppColors.warning,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Teacher Feedback Button
              _buildFeedbackButtonInGrid(context),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Một mục Legend nhỏ: ô màu + nhãn chữ
  Widget _buildPaletteLegendItem(
    Color bgColor,
    Color borderColor,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackButtonInGrid(BuildContext context) {
    final user = context.read<AuthViewModel>().currentUser;
    if (user?.classId == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.indigo50,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClassFeedbackScreen()),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.primary),
        label: const Text(
          'GỬI Ý KIẾN GIÁO VIÊN',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // Mở ảnh full screen với Hero animation + pinch zoom
  void _openFullscreenImage(BuildContext ctx, String imageUrl) {
    Navigator.of(ctx).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => _FullscreenImageViewer(imageUrl: imageUrl),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  // Hỏi người dùng có muốn thoát giữa chừng không
  Future<bool?> _showExitConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            'Hủy làm bài?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: const Text(
          'Nếu bạn thoát ngay bây giờ, toàn bộ tiến trình làm bài sẽ bị mất và không được lưu lại.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Tiếp tục', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Thoát', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Chặn back khi đang làm bài (không phải review mode)
      canPop: widget.isReviewMode || _isSubmitted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmDialog();
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child:
          _showInstruction &&
              _selectedPart != null &&
              (_selectedPart!.instructions != null ||
                  _selectedPart!.instructionImgUrl != null)
          ? _buildInstructionScreen(context)
          : Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(
                  widget.test.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                actions: [
                  Consumer<PracticeViewModel>(
                    builder: (context, viewModel, child) {
                      final currentQId = viewModel.currentQuestions.isNotEmpty && _currentIndex < viewModel.currentQuestions.length 
                          ? viewModel.currentQuestions[_currentIndex].id 
                          : null;
                      
                      return Row(
                        children: [
                          if (currentQId != null && !widget.isReviewMode)
                            IconButton(
                              icon: Icon(
                                _flaggedQuestions.contains(currentQId)
                                    ? Icons.flag_rounded
                                    : Icons.flag_outlined,
                                color: _flaggedQuestions.contains(currentQId)
                                    ? Colors.amber
                                    : Colors.white70,
                              ),
                              onPressed: () => _toggleFlag(currentQId),
                            ),
                          if (widget.isReviewMode || _isSubmitted)
                            IconButton(
                              icon: const Icon(Icons.grid_view_rounded),
                              onPressed: () => _showQuestionGrid(
                                context,
                                viewModel.currentQuestions,
                              ),
                            ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Text(
                                '${_currentIndex + 1}/${viewModel.currentQuestions.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              body: Consumer<PracticeViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final questions = viewModel.currentQuestions;
                  if (questions.isEmpty) {
                    return const Center(child: Text("Không có câu hỏi."));
                  }

                  return Column(
                    children: [
                      _buildAudioPlayer(),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          physics: widget.isReviewMode
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          onPageChanged: _onPageChanged,
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final question = questions[index];
                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index == 0 && widget.overallFeedback != null && widget.overallFeedback!.isNotEmpty)
                                    _buildOverallAssessmentCard(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Câu ${index + 1}',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      if (_isTimed && !_isSubmitted)
                                        Text(
                                          _formatDuration(_remainingTime),
                                          style: TextStyle(
                                            color: _remainingTime.inMinutes < 5
                                                ? Colors.red
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  if (question.imageUrl != null)
                                    GestureDetector(
                                      onTap: () => _openFullscreenImage(
                                        context,
                                        question.imageUrl!,
                                      ),
                                      child: Hero(
                                        tag: 'passage_img_${question.id}',
                                        child: Container(
                                          height: 250,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                child: Image.network(
                                                  question.imageUrl!,
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                ),
                                              ),
                                              // Hint icon để biết có thể tap
                                              Positioned(
                                                bottom: 10,
                                                right: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.zoom_in_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 16),

                                  _buildOption(
                                    question.id,
                                    'A',
                                    question.optionA,
                                    question.correctAnswer,
                                  ),
                                  _buildOption(
                                    question.id,
                                    'B',
                                    question.optionB,
                                    question.correctAnswer,
                                  ),
                                  _buildOption(
                                    question.id,
                                    'C',
                                    question.optionC,
                                    question.correctAnswer,
                                  ),
                                  _buildOption(
                                    question.id,
                                    'D',
                                    question.optionD,
                                    question.correctAnswer,
                                  ),

                                  if (widget.isReviewMode)
                                    _buildAIFeedbackArea(question, index),

                                  const SizedBox(height: 12),
                                  if (_isSubmitted) ...[
                                    const SizedBox(height: 12),
                                    _buildTranscriptReview(question),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      _buildBottomNavigation(questions),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildAIFeedbackArea(QuestionModel question, int index) {
    final userAnswer = _userAnswers[question.id];
    final isCorrect = userAnswer == question.correctAnswer;

    // Logic: If incorrect and has AI feedback, show the orange tip card.
    // If it has explanation, show the blue explanation card.

    final bool hasAIFeedback = widget.aiFeedbacks != null;
    final bool hasExplanation =
        question.explanation != null && question.explanation!.isNotEmpty;

    if (!hasAIFeedback && !hasExplanation) return const SizedBox.shrink();

    return Column(
      children: [
        if (hasAIFeedback && !isCorrect)
          _buildAITipCard(question.questionNumber),
        if (hasExplanation) ...[
          const SizedBox(height: 16),
          _buildExplanationCard(question),
        ],
      ],
    );
  }

  Widget _buildExplanationCard(QuestionModel question) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Phân tích từ AI',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question.questionTranslation != null &&
                    question.questionTranslation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Dịch câu hỏi: ${question.questionTranslation}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                if (question.analysis != null && question.analysis!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HtmlWidget(
                      '<b>Phân tích:</b><br/>${question.analysis}',
                      textStyle: GoogleFonts.inter(fontSize: 14, height: 1.5),
                    ),
                  ),
                if (question.evidence != null && question.evidence!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HtmlWidget(
                      '<b>Bằng chứng:</b><br/>${question.evidence}',
                      textStyle: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                if (question.explanation != null &&
                    question.explanation!.isNotEmpty &&
                    (question.analysis == null || question.analysis!.isEmpty))
                  HtmlWidget(
                    question.explanation!,
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.6,
                      color: const Color(0xFF475569),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITipCard(int questionNumber) {
    final feedback = widget.aiFeedbacks!.firstWhere(
      (f) => (f is Map && f['questionNumber'] == questionNumber) || f == null,
      orElse: () => null,
    );

    if (feedback == null) return const SizedBox.shrink();
    final String tipText =
        feedback['tip'] ?? feedback['comment'] ?? feedback['feedback'] ?? '';
    if (tipText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Light Orange
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gia sư AI nhận xét:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tipText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    if (_selectedPart?.audioUrl == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CustomAudioPlayer(
        audioUrl: _selectedPart!.audioUrl!,
        autoPlay: !widget.isReviewMode,
      ),
    );
  }

  Widget _buildOption(String qId, String label, String? text, String? correct) {
    if (text == null) return const SizedBox.shrink();

    bool isSelected = _userAnswers[qId] == label;
    bool isCorrect = correct == label;

    Color color = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = Colors.black87;

    if (_isSubmitted) {
      if (isCorrect) {
        color = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981);
        textColor = const Color(0xFF065F46);
      } else if (isSelected) {
        color = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFF991B1B);
      }
    } else if (isSelected) {
      borderColor = const Color(0xFF2563EB);
      color = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF2563EB);
    }

    return GestureDetector(
      onTap: () => _onOptionSelected(qId, label),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: (isSelected || (_isSubmitted && isCorrect)) ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: (isSelected || (_isSubmitted && isCorrect))
                  ? borderColor
                  : Colors.grey[100],
              child: Text(
                label,
                style: TextStyle(
                  color: (isSelected || (_isSubmitted && isCorrect))
                      ? Colors.white
                      : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Đáp án $label",
                style: GoogleFonts.inter(
                  color: textColor,
                  fontWeight: (isSelected || (_isSubmitted && isCorrect))
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (_isSubmitted && isCorrect)
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            if (_isSubmitted && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptReview(QuestionModel question) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transcript:",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          _buildTranscriptRow('A', question.optionA ?? ""),
          const Divider(height: 8),
          _buildTranscriptRow('B', question.optionB ?? ""),
          const Divider(height: 8),
          _buildTranscriptRow('C', question.optionC ?? ""),
          const Divider(height: 8),
          _buildTranscriptRow('D', question.optionD ?? ""),
        ],
      ),
    );
  }

  Widget _buildTranscriptRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "($label) ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: TouchablePassageWidget(
              htmlContent: text,
              translations: const [],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(List<QuestionModel> questions) {
    if (widget.isReviewMode) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini Palette
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: questions.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, i) {
                  final colorInfo = _getPaletteColorInfo(i, questions);
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 40,
                      decoration: BoxDecoration(
                        color: colorInfo['bg'],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorInfo['border'],
                          width: colorInfo['shadow'] == true ? 2 : 1.5,
                        ),
                        boxShadow: colorInfo['shadow'] == true
                            ? AppShadows.softShadow
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colorInfo['text'],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text(
                    "Đóng chế độ xem lại",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12).copyWith(bottom: 24),
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
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousPage,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text(
                  "Câu trước",
                  style: TextStyle(color: Colors.black87),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentIndex < questions.length - 1) {
                  _nextPage();
                } else if (!_isSubmitted) {
                  _submitTest();
                } else {
                  Navigator.pop(context);
                }
              },
              icon: Icon(
                _currentIndex < questions.length - 1
                    ? Icons.arrow_forward_rounded
                    : (_isSubmitted
                          ? Icons.check_circle_rounded
                          : Icons.send_rounded),
                size: 16,
              ),
              label: Text(
                _currentIndex < questions.length - 1
                    ? "Câu tiếp"
                    : (_isSubmitted ? "Hoàn thành" : "Nộp bài"),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionScreen(BuildContext context) {
    const Color adminBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _selectedPart?.partName ?? 'Part 1: Photographs',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: adminBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Directions Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: adminBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: adminBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Directions",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Image (if any)
                  if (_selectedPart?.instructionImgUrl != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _selectedPart!.instructionImgUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Instructions Content (Supports HTML)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: HtmlWidget(
                      _selectedPart?.instructions ??
                          "Bạn sẽ thấy một bức ảnh cho mỗi câu hỏi. Hãy nghe 4 phương án mô tả và chọn đáp án đúng nhất. Lưu ý: Các phương án sẽ không được in trong đề thi.",
                      textStyle: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.7,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Button Area
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => setState(() => _showInstruction = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Bắt đầu làm bài",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallAssessmentCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF59E0B).withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_alt_rounded, color: Color(0xFFF59E0B), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG KẾT TỪ AI COACH',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF92400E),
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Phân tích năng lực làm bài của bạn',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB45309),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF59E0B), thickness: 0.5),
          ),
          HtmlWidget(
            widget.overallFeedback!,
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: const Color(0xFF92400E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen Image Viewer — pinch để zoom, nhấn X để đóng
class _FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const _FullscreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Ảnh đoạn văn',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          scaleEnabled: true, // Bật zoom
          minScale: 0.5, // Thu nhỏ tối đa 0.5x
          maxScale: 5.0, // Phóng to tối đa 5x
          boundaryMargin: const EdgeInsets.all(20), // Thêm vùng đệm khi kéo
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

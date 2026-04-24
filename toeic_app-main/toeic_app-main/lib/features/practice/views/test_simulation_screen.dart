import 'dart:async';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../constants/app_constants.dart';
import '../models/exam_model.dart';
import '../models/part_model.dart';
import '../viewmodels/practice_viewmodel.dart';
import 'practice_result_screen.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/touchable_passage_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import 'class_feedback_screen.dart';

class TestSimulationScreen extends StatefulWidget {
  final ExamModel test;
  final String? partId;

  const TestSimulationScreen({super.key, required this.test, this.partId});

  @override
  State<TestSimulationScreen> createState() => _TestSimulationScreenState();
}

class _TestSimulationScreenState extends State<TestSimulationScreen> {
  bool _showInstruction = true;
  PartModel? _selectedPart;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // State for tracking answers and flags
  final Map<String, String> _userAnswers = {};
  final Set<String> _flaggedQuestions = {};
  bool _isSubmitted = false;
  bool _isSubmitting = false;

  // Time Tracking State
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isTimed = false;
  final Map<int, int> _timePerQuestion = {}; // questionIndex -> seconds spent
  Timer? _questionTimer;
  double _topPaneFlex = 0.4;

  @override
  void initState() {
    super.initState();
    if (widget.partId != null) {
      try {
        _selectedPart = widget.test.parts.firstWhere(
          (p) => p.id == widget.partId,
        );
      } catch (e) {
        // Part not found
      }
    } else {
      _showInstruction = false;
    }
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSubmitted && !_isSubmitting) {
        _timePerQuestion[_currentIndex] =
            (_timePerQuestion[_currentIndex] ?? 0) + 1;

        // Time Tracking Alert (40s for P5, 90s for others)
        final bool isPart5 = _selectedPart?.partNumber == 5;
        final int limit = isPart5 ? 40 : 90;
        if (_timePerQuestion[_currentIndex] == limit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '⏳ Gợi ý: Hãy cắm cờ và chuyển sang câu tiếp theo để tránh lố giờ!',
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isTimed && _selectedPart?.timeLimit != null) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hết giờ làm bài!')));
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
    if (_isSubmitted || _isSubmitting) {
      return; // Prevent changing answers after submission
    }
    setState(() {
      _userAnswers[questionId] = option;
    });
  }

  void _toggleFlag(String questionId) {
    setState(() {
      if (_flaggedQuestions.contains(questionId)) {
        _flaggedQuestions.remove(questionId);
      } else {
        _flaggedQuestions.add(questionId);
      }
    });
  }

  Future<void> _submitTest() async {
    if (_isSubmitting) {
      return;
    }

    _timer?.cancel();
    _questionTimer?.cancel();

    setState(() {
      _isSubmitting = true;
    });

    final viewModel = context.read<PracticeViewModel>();
    // final questions = viewModel.currentQuestions; // Removed unused variable

    // Total time calculation
    int totalTime = 0;
    for (var t in _timePerQuestion.values) {
      totalTime += t;
    }

    // Call API submit
    final result = await viewModel.submitPart(
      widget.partId!,
      _userAnswers,
      timeTaken: totalTime,
    );

    if (mounted) {
      if (result != null) {
        setState(() {
          _isSubmitted = true;
          _isSubmitting = false;
        });

        // Navigate to new Result Screen with AI
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PracticeResultScreen(
              resultData: {
                ...result, 
                'userAnswers': _userAnswers,
                'flaggedQuestions': _flaggedQuestions.toList(),
              },
              part: _selectedPart!,
              attemptId: (result['attemptId'] ?? result['id']).toString(),
              fromSimulation: true,
            ),
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi nộp bài. Vui lòng thử lại!')),
        );
      }
    }
  }

  // Xác định màu sắc cho ô câu hỏi trong Bottom Sheet.
  Map<String, dynamic> _getBottomSheetColorInfo(
      String qId, int index, List<dynamic> questions) {
    final bool isCurrent = index == _currentIndex;
    final bool isFlagged = _flaggedQuestions.contains(qId);
    final bool isAnswered = _userAnswers.containsKey(qId);

    // Default styles
    Map<String, dynamic> info = {
      'bg': Colors.white,
      'border': AppColors.divider,
      'text': AppColors.textSecondary,
      'shadow': false,
      'borderWidth': 1.5,
    };

    // 1. Priority: Correct/Incorrect if submitted
    if (_isSubmitted && isAnswered) {
      final userAnswer = _userAnswers[qId];
      final questionList = context.read<PracticeViewModel>().currentQuestions;
      if (index < questionList.length) {
        final correctAnswer = questionList[index].correctAnswer;
        final isCorrect = userAnswer == correctAnswer;

        if (isCorrect) {
          info['bg'] = const Color(0xFF10B981);
          info['border'] = const Color(0xFF059669);
          info['text'] = Colors.white;
        } else {
          info['bg'] = const Color(0xFFEF4444);
          info['border'] = const Color(0xFFDC2626);
          info['text'] = Colors.white;
        }
      }
    } else if (isAnswered && !_isSubmitted) {
      // Only show purple background if NOT submitted
      info['bg'] = AppColors.primary;
      info['border'] = const Color(0xFF1E3A8A);
      info['text'] = Colors.white;
    }

    // 2. Override for Flagged (High Priority Visibility during test)
    if (isFlagged && !_isSubmitted) {
      info['bg'] = const Color(0xFFF59E0B);
      info['border'] = const Color(0xFFD97706);
      info['text'] = Colors.white;
    }

    // 3. Highlight Current
    if (isCurrent) {
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

  void _showQuestionPalette() {
    final viewModel = context.read<PracticeViewModel>();
    final questions = viewModel.currentQuestions;
    final user = context.read<AuthViewModel>().currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Chú thích màu sắc (Legend)
            _buildPaletteLegend(),
            const SizedBox(height: 20),

            // Grid các ô số câu hỏi
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final qId = questions[index].id;
                  final colorInfo = _getBottomSheetColorInfo(qId, index, questions);
                  final bool isFlagged = _flaggedQuestions.contains(qId);

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pageController.jumpToPage(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
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
                            '${questions[index].questionNumber}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorInfo['text'],
                            ),
                          ),
                          // Biểu tượng cờ nhỏ ở góc phải trên nếu câu bị đánh dấu
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
            
            // Teacher Feedback Button at the very bottom
            if (user?.classId != null) ...[
              const SizedBox(height: 16),
              Container(
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPartInstructions() {
    if (_selectedPart == null) return;
    const Color adminBlue = Color(0xFF2563EB);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle and Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: adminBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: adminBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedPart!.partName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image (if any)
                    if (_selectedPart!.instructionImgUrl != null && _selectedPart!.instructionImgUrl!.trim().isNotEmpty)
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
                            AppConstants.getFullUrl(_selectedPart!.instructionImgUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Instructions Content (HTML)
                    if (_selectedPart!.instructions != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: HtmlWidget(
                          _selectedPart!.instructions!,
                          textStyle: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.7,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    // Tip/Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Đọc kỹ hướng dẫn giúp bạn tránh những sai sót không đáng có khi làm bài.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget chú thích màu sắc, hiển thị trước Grid
  Widget _buildPaletteLegend() {
    // Dùng Wrap để các mục tự xuống dòng nếu không đủ chỗ
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendChip(const Color(0xFFF59E0B), const Color(0xFFD97706), 'Cắm cờ'),
        if (_isSubmitted) ...[
          _buildLegendChip(const Color(0xFF10B981), const Color(0xFF059669), 'Đúng'),
          _buildLegendChip(const Color(0xFFEF4444), const Color(0xFFDC2626), 'Sai'),
        ],
        _buildLegendChip(Colors.white, AppColors.divider, 'Chưa trả lời'),
      ],
    );
  }

  // Một mục nhỏ trong Legend với ô màu và nhãn chữ
  Widget _buildLegendChip(Color bgColor, Color borderColor, String label) {
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


  String _buildPassageHtml(String rawPassage, int activeQuestionNumber) {
    final regex = RegExp(r'\[(\d+)\]');
    return rawPassage.replaceAllMapped(regex, (match) {
      final num = match.group(1) ?? '';
      final isActive = num == activeQuestionNumber.toString();
      if (isActive) {
        // Active: Solid Indigo Premium Badge (Q147)
        return '<span style="background: #4F46E5; color: #ffffff; '
            'border-radius: 6px; padding: 2px 10px; font-weight: 700; '
            'display: inline-flex; align-items: center; justify-content: center; '
            'box-shadow: 0 2px 5px rgba(0,0,0,0.15); '
            'font-size: 13px; margin: 0 4px; font-family: sans-serif;">'
            'Q$num</span>';
      } else {
        // Inactive: Clean Slate Border Badge (#147)
        return '<span style="background: #F8FAFC; color: #475569; '
            'border: 1px solid #CBD5E1; border-radius: 4px; padding: 1px 8px; '
            'font-weight: 600; display: inline-flex; font-size: 12px; '
            'margin: 0 4px; font-family: sans-serif;">'
            '#$num</span>';
      }
    });
  }

  Widget _buildPassageHeader(
    String passage,
    List<Map<String, dynamic>> translations,
    int activeQuestionNumber,
    List<String> passageImageUrls,
    String? passageTitle,
  ) {
    const Color adminBlue = Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: adminBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.article_outlined, size: 16, color: adminBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Đoạn văn',
                      style: TextStyle(
                        color: adminBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildThemeBadge('Đọc Thông minh'),
            ],
          ),
          const SizedBox(height: 16),
          if (passageTitle != null && passageTitle.isNotEmpty) ...[
            Text(
              passageTitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: adminBlue,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: TouchablePassageWidget(
                htmlContent: _buildPassageHtml(passage, activeQuestionNumber),
                translations: translations,
                textStyle: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF334155),
                  fontFamily: 'Tinos',
                ),
              ),
            ),
          ),
          // Passage Images moved BELOW the text/title
          // [REQ] Hide for Part 6 & 7 to focus on Touch-to-Translate
          if (passageImageUrls.where((u) => u.isNotEmpty).isNotEmpty && 
              _selectedPart?.partNumber != 6 && _selectedPart?.partNumber != 7) ...[
            const SizedBox(height: 16),
            Column(
              children: passageImageUrls.where((u) => u.isNotEmpty).map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _openFullscreenImage(context, url),
                  child: Hero(
                    tag: 'passage_img_$url',
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AppConstants.getFullUrl(url).isEmpty
                            ? const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey))
                            : Image.network(
                                AppConstants.getFullUrl(url),
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                ),
                                loadingBuilder: (ctx, child, prog) =>
                                    prog == null ? child : const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                              ),
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: Colors.amber.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Chặn back khi đang làm bài (chưa submit)
      canPop: _isSubmitted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmDialog();
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _showInstruction &&
              _selectedPart != null &&
              (_selectedPart!.instructions != null || (_selectedPart!.instructionImgUrl != null && _selectedPart!.instructionImgUrl!.trim().isNotEmpty))
          ? _buildInstructionScreen(context)
          : Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedPart?.partName ?? widget.test.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Consumer<PracticeViewModel>(builder: (context, vm, child) {
              final String? qId = vm.currentQuestions.length > _currentIndex 
                  ? vm.currentQuestions[_currentIndex].id : null;
              final bool isFlagged = qId != null && _flaggedQuestions.contains(qId);
              return Icon(
                isFlagged ? Icons.flag_rounded : Icons.flag_outlined,
                color: isFlagged ? Colors.amber : Colors.white70,
              );
            }),
            onPressed: () {
              final vm = context.read<PracticeViewModel>();
              if (vm.currentQuestions.length > _currentIndex) {
                _toggleFlag(vm.currentQuestions[_currentIndex].id);
              }
            },
            tooltip: 'Cắm cờ câu này',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showPartInstructions,
            color: Colors.white70,
            tooltip: 'Hướng dẫn làm bài',
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: _showQuestionPalette,
            color: Colors.white,
            tooltip: 'Bảng câu hỏi',
          ),
          const SizedBox(width: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _formatDuration(_remainingTime),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_m6cuL6.json',
                    height: 150,
                    errorBuilder: (context, error, stackTrace) =>
                        const CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 20),
                  const Text('AI đang chấm bài của bạn...'),
                ],
              ),
            )
          : Consumer<PracticeViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.error != null) {
                  return Center(child: Text('Error: ${viewModel.error}'));
                }

                final questions = viewModel.currentQuestions;

                if (questions.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)?.translate('no_questions') ??
                          'Không có câu hỏi nào.',
                    ),
                  );
                }

                final bool isReadingPartWithPassage =
                    _selectedPart?.partNumber == 6 ||
                    _selectedPart?.partNumber == 7;
                final currentQuestion = questions[_currentIndex];
                final String? currentPassage = currentQuestion.passage;

                if (isReadingPartWithPassage &&
                    currentPassage != null &&
                    currentPassage.isNotEmpty) {
                  return Column(
                    children: [
                      // TOP: Passage (Scrollable + Touchable)
                      Expanded(
                        flex: (_topPaneFlex * 1000).toInt(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildPassageHeader(currentPassage, currentQuestion.passageTranslations, currentQuestion.questionNumber, currentQuestion.passageImageUrls, currentQuestion.passageTitle),
                                // Nếu câu hỏi có ảnh (Magic Scan image) — hiển thị tapable
                                if (currentQuestion.imageUrl != null && currentQuestion.imageUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () => _openFullscreenImage(context, currentQuestion.imageUrl!),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          constraints: const BoxConstraints(maxHeight: 260),
                                          margin: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: AppShadows.softShadow,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: AppConstants.getFullUrl(currentQuestion.imageUrl).isEmpty
                                                ? const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey))
                                                : Image.network(
                                                    AppConstants.getFullUrl(currentQuestion.imageUrl),
                                                    fit: BoxFit.contain,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    errorBuilder: (context, error, stackTrace) => const Center(
                                                      child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                                    ),
                                                    loadingBuilder: (ctx, child, prog) =>
                                                        prog == null ? child : const Center(child: CircularProgressIndicator()),
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 24,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.indigo50.withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // DRAGGABLE DIVIDER
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            double delta = details.primaryDelta! / MediaQuery.of(context).size.height;
                            _topPaneFlex = (_topPaneFlex + delta).clamp(0.2, 0.75);
                          });
                        },
                        child: Container(
                          height: 24,
                          width: double.infinity,
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // BOTTOM: Question Area
                      Expanded(
                        flex: ((1.0 - _topPaneFlex) * 1000).toInt(),
                        child: _buildQuestionArea(questions),
                      ),
                      _buildMiniPalette(questions.length),
                      _buildBottomNavigation(questions.length),
                    ],
                  );
                }

                // Part 5 / No Passage View
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.indigo50.withValues(alpha: 0.5),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: _buildQuestionArea(questions),
                          ),
                        ),
                      ),
                      _buildMiniPalette(questions.length),
                      _buildBottomNavigation(questions.length),
                    ],
                  ),
                );
              },
            ),
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
          child: Text('Hủy làm bài?', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  child: const Text(
                    'Tiếp tục',
                    textAlign: TextAlign.center,
                  ),
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
                  child: const Text(
                    'Thoát',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(List<dynamic> questions) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Câu ${question.questionNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  if (_flaggedQuestions.contains(question.id))
                    const Chip(
                      label: Text(
                        'Đang cắm cờ',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (question.questionText != null)
                HtmlWidget(
                  question.questionText!,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 16),
              // NEW: Question Image (e.g. for Part 5 or specific Magic Scan)
              if (question.imageUrl != null && question.imageUrl!.isNotEmpty && _selectedPart?.partNumber != 2 && _selectedPart?.partNumber != 5) ...[
                GestureDetector(
                  onTap: () => _openFullscreenImage(context, question.imageUrl!),
                  child: Hero(
                    tag: 'q_img_${question.id}',
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 260),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                      child: AppConstants.getFullUrl(question.imageUrl).isEmpty
                          ? const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey))
                          : Image.network(
                              AppConstants.getFullUrl(question.imageUrl),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                              ),
                              loadingBuilder: (ctx, child, prog) =>
                                  prog == null ? child : const Center(child: CircularProgressIndicator()),
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 24),
              _buildOption(
                context,
                question.id,
                'A',
                question.optionA,
                question.correctAnswer,
              ),
              _buildOption(
                context,
                question.id,
                'B',
                question.optionB,
                question.correctAnswer,
              ),
              _buildOption(
                context,
                question.id,
                'C',
                question.optionC,
                question.correctAnswer,
              ),
              _buildOption(
                context,
                question.id,
                'D',
                question.optionD,
                question.correctAnswer,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniPalette(int total) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final vm = context.read<PracticeViewModel>();
          final questions = vm.currentQuestions;
          final String? qId = questions.length > index 
              ? questions[index].id : null;
          
          final bool isCurrent = index == _currentIndex;
          final bool isAnswered = qId != null && _userAnswers.containsKey(qId);
          final bool isFlagged = qId != null && _flaggedQuestions.contains(qId);

          Color bgColor = Colors.white;
          Color textColor = AppColors.textSecondary;
          Color borderColor = AppColors.divider;

          if (isCurrent) {
            bgColor = AppColors.primary;
            textColor = Colors.white;
            borderColor = AppColors.primary;
          } else if (isFlagged) {
            bgColor = const Color(0xFFFFF7ED);
            textColor = AppColors.warning;
            borderColor = AppColors.warning;
          } else if (isAnswered) {
            bgColor = AppColors.indigo50;
            textColor = AppColors.primary;
            borderColor = AppColors.primary.withValues(alpha: 0.5);
          }

          return GestureDetector(
            onTap: () => _pageController.jumpToPage(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              width: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: isCurrent ? AppShadows.softShadow : [],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '${questions[index].questionNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isFlagged)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(
                        Icons.flag,
                        size: 8,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String questionId,
    String optionLabel,
    String? optionText,
    String? correctAnswer,
  ) {
    if (optionText == null || optionText.isEmpty) {
      return const SizedBox.shrink();
    }

    bool isSelected = _userAnswers[questionId] == optionLabel;

    return GestureDetector(
      onTap: () => _onOptionSelected(questionId, optionLabel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indigo50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.softShadow : [],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : AppColors.background,
              ),
              child: Text(
                optionLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(int totalQuestions) {

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          // Lùi lại
          if (_currentIndex > 0)
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: _previousPage,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Câu trước'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          // Nút Tiếp theo / Nộp bài
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentIndex < totalQuestions - 1) {
                  _nextPage();
                } else {
                  _submitTest();
                }
              },
              icon: Icon(
                _currentIndex < totalQuestions - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.send_rounded,
                size: 16,
              ),
              label: Text(
                _currentIndex < totalQuestions - 1 ? 'Câu tiếp' : 'Nộp bài ngay',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentIndex < totalQuestions - 1
                    ? AppColors.primary
                    : AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
          _selectedPart?.partName ?? 'Instructions',
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
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Directions Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: adminBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: adminBlue, size: 20),
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
                  if (_selectedPart?.instructionImgUrl != null && _selectedPart!.instructionImgUrl!.trim().isNotEmpty)
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
                        child: AppConstants.getFullUrl(_selectedPart!.instructionImgUrl).isEmpty
                            ? const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey))
                            : Image.network(
                                AppConstants.getFullUrl(_selectedPart!.instructionImgUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                ),
                              ),
                      ),
                    ),

                  // Instructions Content (HTML)
                  if (_selectedPart!.instructions != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: HtmlWidget(
                        _selectedPart!.instructions!,
                        textStyle: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.7,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
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
                onPressed: () {
                  setState(() {
                    _showInstruction = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)?.translate('start') ?? "Bắt đầu ngay",
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

  // Mở ảnh full màn hình với pinch zoom
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
}

/// Fullscreen Image Viewer — pinch để zoom (tối đa 5x), nhấn X để đóng
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
          minScale: 0.5,      // Thu nhỏ tối đa 0.5x
          maxScale: 5.0,      // Phóng to tối đa 5x
          boundaryMargin: const EdgeInsets.all(20), // Thêm vùng đệm khi kéo
          child: AppConstants.getFullUrl(imageUrl).isEmpty
              ? const Center(child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey))
              : Image.network(
                  AppConstants.getFullUrl(imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,
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

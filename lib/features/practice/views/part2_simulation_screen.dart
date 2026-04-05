import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/question_model.dart';
import '../models/part_model.dart';
import '../viewmodels/practice_viewmodel.dart';
import './widgets/custom_audio_player.dart';
import './practice_result_screen.dart';
import '../../../constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class Part2SimulationScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final String? partAudioUrl;
  final bool isReviewMode;
  final Map<String, String>? userAnswers;
  final PartModel? part; // Add part model for submission
  final List<dynamic>? aiFeedbacks;
  final String? overallFeedback;

  const Part2SimulationScreen({
    super.key,
    required this.questions,
    this.partAudioUrl,
    this.isReviewMode = false,
    this.userAnswers,
    this.part,
    this.aiFeedbacks,
    this.overallFeedback,
  });

  @override
  State<Part2SimulationScreen> createState() => _Part2SimulationScreenState();
}

class _Part2SimulationScreenState extends State<Part2SimulationScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  Map<String, String> _selectedAnswers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.isReviewMode && widget.userAnswers != null) {
      _selectedAnswers = Map.from(widget.userAnswers!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onOptionSelected(String questionId, String option) {
    if (widget.isReviewMode) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswers[questionId] = option;
    });

    // Auto navigate to next question after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_currentIndex < widget.questions.length - 1 && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isReviewMode ? 'Xem lại Part 2' : 'Phần 2: Question-Response',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (widget.questions.isEmpty) ? 0 : (_currentIndex + 1) / widget.questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.questions.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildQuestionPage(widget.questions[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isReviewMode ? null : _buildBottomActions(),
    );
  }

  Widget _buildQuestionPage(QuestionModel question) {
    final String selectedOption = _selectedAnswers[question.id] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_currentIndex == 0 && widget.overallFeedback != null && widget.overallFeedback!.isNotEmpty)
            _buildOverallAssessmentCard(),
          const SizedBox(height: 10),
          Text(
            'Câu hỏi ${question.questionNumber}',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey[900],
            ),
          ),
          const SizedBox(height: 24),
          
          // Audio Player - Specific or Generic
          CustomAudioPlayer(
            audioUrl: (question.audioUrl != null && question.audioUrl!.isNotEmpty) 
                ? question.audioUrl! 
                : (widget.partAudioUrl ?? ''),
            autoPlay: true,
          ),
          
          const SizedBox(height: 40),

          // NEW: AI Feedback Area
          if (widget.isReviewMode) ...[
            _buildAIFeedbackArea(question, _currentIndex),
            const SizedBox(height: 24),
          ],
          
          // Review Content (English Tapescript Only - NO AI)
          if (widget.isReviewMode) ...[
            _buildTapescriptSection(question),
            const SizedBox(height: 30),
          ],

          // Large Reflex Buttons (A, B, C)
          _buildOptionButtons(question, selectedOption),
          
          const SizedBox(height: 40),
          
          if (!widget.isReviewMode)
            Text(
              'Chọn nhanh đáp án bạn nghe được!',
              style: TextStyle(
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTapescriptSection(QuestionModel question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'English Tapescript',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.questionText ?? 'Listen to the question.',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 24),
          _buildTapescriptOption('A', question.optionA),
          _buildTapescriptOption('B', question.optionB),
          _buildTapescriptOption('C', question.optionC),
        ],
      ),
    );
  }

  Widget _buildTapescriptOption(String label, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '($label) ',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButtons(QuestionModel question, String selectedOption) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildBigButton('A', question, selectedOption)),
            const SizedBox(width: 16),
            Expanded(child: _buildBigButton('B', question, selectedOption)),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: _buildBigButton('C', question, selectedOption),
          ),
        ),
      ],
    );
  }

  Widget _buildBigButton(String option, QuestionModel question, String selectedOption) {
    final bool isSelected = selectedOption == option;
    final bool isCorrect = widget.isReviewMode && question.correctAnswer == option;
    final bool isWrong = widget.isReviewMode && isSelected && question.correctAnswer != option;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey[200]!;
    Color textColor = Colors.black87;

    if (widget.isReviewMode) {
      if (isCorrect) {
        bgColor = Colors.green[50]!;
        borderColor = Colors.green;
        textColor = Colors.green[700]!;
      } else if (isWrong) {
        bgColor = Colors.red[50]!;
        borderColor = Colors.red;
        textColor = Colors.red[700]!;
      } else if (isSelected) {
        bgColor = Colors.grey[100]!;
        borderColor = Colors.grey;
      }
    } else {
      if (isSelected) {
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        borderColor = AppColors.primary;
        textColor = AppColors.primary;
      }
    }

    return GestureDetector(
      onTap: () => _onOptionSelected(question.id, option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: isSelected || (widget.isReviewMode && isCorrect) ? 2.5 : 1),
          boxShadow: [
            if (isSelected && !widget.isReviewMode)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            option,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _currentIndex > 0 
                ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                : null,
              icon: const Icon(Icons.arrow_back_ios),
              color: AppColors.primary,
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(180, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Nộp bài Part 2', 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
            ),
            IconButton(
              onPressed: _currentIndex < widget.questions.length - 1
                ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                : null,
              icon: const Icon(Icons.arrow_forward_ios),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTest() async {
    if (widget.part == null) return;
    
    setState(() {
      _isSubmitting = true;
    });

    final viewModel = context.read<PracticeViewModel>();
    
    // Calculate raw score for fallback/display
    int correctCount = 0;
    for (var q in widget.questions) {
      if (_selectedAnswers[q.id] == q.correctAnswer) {
        correctCount++;
      }
    }

    String attemptId = '0';
    Map<String, dynamic>? submitResult;

    try {
      submitResult = await viewModel.submitPart(
        widget.part!.id,
        _selectedAnswers,
        timeTaken: 0, // Part 2 is often short, or add timer later
      );
      
      if (submitResult != null) {
        attemptId = (submitResult['attemptId'] ?? submitResult['id']).toString();
      }
    } catch (e) {
      debugPrint("Part 2 submit error: $e");
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    // Navigate to Result Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeResultScreen(
          resultData: {
            'score': correctCount,
            'totalQuestions': widget.questions.length,
            'userAnswers': _selectedAnswers,
            ...?submitResult,
          },
          part: widget.part!,
          attemptId: attemptId,
        ),
      ),
    );
  }

  Widget _buildAIFeedbackArea(QuestionModel question, int index) {
    if (widget.aiFeedbacks == null) return const SizedBox.shrink();

    // Find feedback by questionNumber to be robust
    final feedbackItem = widget.aiFeedbacks!.firstWhere(
      (f) =>
          (f is Map && f['questionNumber'] == question.questionNumber) ||
          (f is Map && f['pnum'] == question.questionNumber),
      orElse: () => null,
    );

    if (feedbackItem == null) return const SizedBox.shrink();

    final String comment = feedbackItem['comment'] ??
        feedbackItem['tip'] ??
        feedbackItem['feedback'] ??
        feedbackItem.toString();
    if (comment.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
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
                const SizedBox(height: 4),
                HtmlWidget(
                  comment,
                  textStyle: GoogleFonts.inter(
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
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
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
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Color(0xFFF59E0B),
                  size: 28,
                ),
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

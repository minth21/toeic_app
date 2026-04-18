import 'dart:convert';
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
  final Set<String>? correctQuestionIds;
  final Set<int>? correctQuestionNumbers; // 🟢 NEW: Fallback for duplicate tests

  const Part2SimulationScreen({
    super.key,
    required this.questions,
    this.partAudioUrl,
    this.isReviewMode = false,
    this.userAnswers,
    this.part,
    this.aiFeedbacks,
    this.overallFeedback,
    this.correctQuestionIds,
    this.correctQuestionNumbers,
  });

  @override
  State<Part2SimulationScreen> createState() => _Part2SimulationScreenState();
}

class _Part2SimulationScreenState extends State<Part2SimulationScreen> {
  Map<String, String> _selectedAnswers = {};
  bool _isSubmitting = false;
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isReviewMode && widget.userAnswers != null) {
      _selectedAnswers = Map.from(widget.userAnswers!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToQuestion(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Calculate approximate offset: Overall card (approx 200) + previous questions (approx 160 each)
    double offset = index == 0 ? 0 : 250.0 + ((index - 1) * 165.0);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Map<String, dynamic> _getPaletteColorInfo(int i, List<QuestionModel> questions) {
    final qId = questions[i].id.trim();
    final bool isActive = i == _currentIndex;
    final String? userAnswer = _selectedAnswers[qId];
    final bool isAnswered = userAnswer != null && userAnswer.trim().isNotEmpty;

    final Map<String, dynamic> info = {
      'bg': Colors.white,
      'border': const Color(0xFFE2E8F0),
      'text': const Color(0xFF64748B),
      'shadow': false,
      'borderWidth': 1.5,
    };

    if (widget.isReviewMode) {
      // 🟢 Aggressive answer normalization: extract only the first A, B, C, or D character
      String clean(String? s) {
        if (s == null || s.isEmpty) return '';
        final match = RegExp(r'[A-D]').firstMatch(s.trim().toUpperCase());
        return match?.group(0) ?? s.trim().toUpperCase();
      }
      
      // 🟢 Dual-Check: Prioritize DB correct status (ID match OR Question Number match)
      bool isCorrect = false;
      if (widget.correctQuestionIds != null || widget.correctQuestionNumbers != null) {
        final inIdSet = widget.correctQuestionIds?.contains(qId) ?? false;
        final qNum = questions[i].questionNumber;
        final inNumSet = widget.correctQuestionNumbers?.contains(qNum) ?? false;
        isCorrect = inIdSet || inNumSet;
        
        // ✅ Diagnostic Log: Log cho câu đầu tiên (Part 2 bắt đầu từ câu 7)
        if (qNum == 7 || qNum == 1) {
          debugPrint('[Part2 Palette Audit] Checking Q#$qNum (ID: $qId): CorrectIds=${widget.correctQuestionIds?.length}, CorrectNums=${widget.correctQuestionNumbers?.length}, MatchID=$inIdSet, MatchNum=$inNumSet -> Final=$isCorrect');
        }
      } else {
        // Fallback to manual comparison (Using robust normalization)
        isCorrect = isAnswered && clean(userAnswer) == clean(questions[i].correctAnswer);
      }



      if (isAnswered) {
        if (isCorrect) {
          info['bg'] = const Color(0xFF10B981); // Emerald 500
          info['border'] = const Color(0xFF059669);
          info['text'] = Colors.white;
        } else {
          info['bg'] = const Color(0xFFEF4444); // Red 500
          info['border'] = const Color(0xFFDC2626);
          info['text'] = Colors.white;
        }
      } else {
        // Not answered but in review mode = treated as wrong (Red)
        info['bg'] = const Color(0xFFEF4444).withValues(alpha: 0.1);
        info['border'] = const Color(0xFFEF4444).withValues(alpha: 0.3);
        info['text'] = const Color(0xFFEF4444);
      }
    } else {
      if (isAnswered) {
        info['bg'] = const Color(0xFF3B82F6);
        info['border'] = const Color(0xFF1E3A8A);
        info['text'] = Colors.white;
      }
    }

    if (isActive) {
      info['border'] = const Color(0xFF2563EB);
      info['borderWidth'] = 3.0;
      info['shadow'] = true;
      if (info['bg'] == Colors.white) {
        info['bg'] = const Color(0xFFEFF6FF);
        info['text'] = const Color(0xFF2563EB);
      }
    }

    return info;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isReviewMode ? 'Xem lại Part 2' : 'Phần 2: Question-Response',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${_selectedAnswers.length}/${widget.questions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Persistent Audio Player ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: CustomAudioPlayer(
              audioUrl:
                  widget.partAudioUrl ??
                  (widget.questions.isNotEmpty
                      ? widget.questions.first.audioUrl ?? ''
                      : ''),
              autoPlay: !widget.isReviewMode,
            ),
          ),

          // ── Progress Indicator ──
          LinearProgressIndicator(
            value: (widget.questions.isEmpty)
                ? 0
                : _selectedAnswers.length / widget.questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
            minHeight: 4,
          ),

          // ── Scrollable Question List ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: widget.questions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  if (widget.overallFeedback != null &&
                      widget.overallFeedback!.isNotEmpty) {
                    return _buildOverallAssessmentCard();
                  }
                  return const SizedBox.shrink();
                }
                return _buildReflexQuestionRow(widget.questions[index - 1]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isReviewMode 
          ? _buildReviewPalette(widget.questions) 
          : _buildBottomActions(),
    );
  }

  Widget _buildReviewPalette(List<QuestionModel> questions) {
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
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: questions.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, i) {
                final colorInfo = _getPaletteColorInfo(i, questions);
                return GestureDetector(
                  onTap: () => _scrollToQuestion(i + 1), // i+1 because index 0 is overall card
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 40,
                    decoration: BoxDecoration(
                      color: colorInfo['bg'],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorInfo['border'],
                        width: colorInfo['borderWidth'] ?? 1.5,
                      ),
                      boxShadow: colorInfo['shadow'] == true
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
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

  Widget _buildReflexQuestionRow(QuestionModel question) {
    final String selectedOption = _selectedAnswers[question.id] ?? '';
    final bool isAnswered = selectedOption.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isAnswered
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isAnswered ? AppColors.primary : AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${question.questionNumber}',
                    style: TextStyle(
                      color: isAnswered ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Horizontal Options A, B, C
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReflexOption(question, 'A', selectedOption),
                    _buildReflexOption(question, 'B', selectedOption),
                    _buildReflexOption(question, 'C', selectedOption),
                  ],
                ),
              ),
            ],
          ),

          // Review mode details
          if (widget.isReviewMode) ...[
            const SizedBox(height: 12),
            _buildReviewDetail(question),
          ],
        ],
      ),
    );
  }

  Widget _buildReflexOption(
    QuestionModel question,
    String option,
    String selectedOption,
  ) {
    final bool isSelected = selectedOption == option;
    // 🟢 Use normalization even for inline styles (with null-safety)
    final String cleanCorrect = (question.correctAnswer ?? '').trim().toUpperCase();
    final bool isCorrect = widget.isReviewMode && cleanCorrect == option;
    final bool isWrong = widget.isReviewMode && isSelected && cleanCorrect != option;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = AppColors.textPrimary;

    if (widget.isReviewMode) {
      if (isCorrect) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
      } else if (isWrong) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
      } else if (isSelected) {
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey;
      }
    } else {
      if (isSelected) {
        bgColor = AppColors.primary;
        borderColor = AppColors.primary;
        textColor = Colors.white;
      }
    }

    return GestureDetector(
      onTap: () => _onOptionSelected(question.id, option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected || (widget.isReviewMode && isCorrect) ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            option,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  void _onOptionSelected(String questionId, String option) {
    if (widget.isReviewMode) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswers[questionId] = option;
    });
  }

  Widget _buildReviewDetail(QuestionModel question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Tapescript',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText ?? 'Listening content...',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 16),
          _buildReviewOptionText(
            'A',
            question.optionA,
            question.correctAnswer == 'A',
          ),
          _buildReviewOptionText(
            'B',
            question.optionB,
            question.correctAnswer == 'B',
          ),
          _buildReviewOptionText(
            'C',
            question.optionC,
            question.correctAnswer == 'C',
          ),

          if (widget.aiFeedbacks != null) ...[
            const SizedBox(height: 12),
            _buildMiniAiFeedback(question),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewOptionText(String label, String? text, bool isCorrect) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '($label) $text',
        style: TextStyle(
          fontSize: 12,
          color: isCorrect ? Colors.green.shade700 : AppColors.textSecondary,
          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMiniAiFeedback(QuestionModel question) {
    final feedbackItem = widget.aiFeedbacks!.firstWhere(
      (f) =>
          (f is Map && f['questionNumber'] == question.questionNumber) ||
          (f is Map && f['pnum'] == question.questionNumber),
      orElse: () => null,
    );

    if (feedbackItem == null) return const SizedBox.shrink();

    final String comment =
        feedbackItem['comment'] ??
        feedbackItem['tip'] ??
        feedbackItem['feedback'] ??
        feedbackItem.toString();
    if (comment.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: HtmlWidget(
        comment,
        textStyle: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitTest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text(
                  'Nộp bài ngay',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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

    // Calculate raw score using ROBUST normalization (matching backend logic)
    int correctCount = 0;
    String clean(String? s) => (s ?? '').trim().toUpperCase();
    
    for (var q in widget.questions) {
      if (clean(_selectedAnswers[q.id]) == clean(q.correctAnswer)) {
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
        attemptId = (submitResult['attemptId'] ?? submitResult['id'])
            .toString();
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

  Widget _buildOverallAssessmentCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.1),
            Colors.white,
          ],
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
          Builder(
            builder: (context) {
              String displayContent = widget.overallFeedback!;
              
              // Kiểm tra và parse nếu là JSON
              if (displayContent.trim().startsWith('{')) {
                try {
                  final decoded = jsonDecode(displayContent);
                  displayContent = decoded['detailedAssessment'] ?? decoded['shortFeedback'] ?? displayContent;
                } catch (e) {
                  debugPrint("Error parsing AI feedback: $e");
                }
              }

              return HtmlWidget(
                displayContent,
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

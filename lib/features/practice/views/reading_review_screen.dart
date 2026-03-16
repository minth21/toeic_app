import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../models/question_model.dart';
import 'widgets/touchable_passage_widget.dart';

/// Unified "Smart Reader" review screen for Reading parts (Part 6 & 7).
/// Redesigned with "Pro Blue" EdTech Premium aesthetic.
class ReadingReviewScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final Map<String, String> userAnswers; // questionId → selectedOption
  final int partNumber;
  final List<dynamic>? aiFeedbacks;

  const ReadingReviewScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.partNumber,
    this.aiFeedbacks,
  });

  @override
  State<ReadingReviewScreen> createState() => _ReadingReviewScreenState();
}

class _ReadingReviewScreenState extends State<ReadingReviewScreen> {
  int _activeIndex = 0;
  late final PageController _pageController;
  final ScrollController _passageScrollController = ScrollController();

  // Premium Palette
  // Theme aliases for cleaner code
  static const Color _primaryBlue = AppColors.primary;
  static const Color _emerald = AppColors.success;
  static const Color _rose = AppColors.error;
  static const Color _slateText = AppColors.textPrimary;
  static const Color _slateSubtext = AppColors.textSecondary;

  double _topPaneFlex = 0.45; // Initial split ratio

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _passageScrollController.dispose();
    super.dispose();
  }

  // ── Passage helpers ────────────────────────────────────────────────────────

  String get _rawPassage => widget.questions.isNotEmpty
      ? (widget.questions[_activeIndex].passage ?? '')
      : '';

  String _buildPassageHtml(int activeQuestionNumber) {
    if (widget.partNumber != 6) {
      return _rawPassage;
    }

    final regex = RegExp(r'\[(\d+)\]');
    return _rawPassage.replaceAllMapped(regex, (match) {
      final num = match.group(1) ?? '';
      final isActive = num == activeQuestionNumber.toString();
      if (isActive) {
        return '<span style="background:#2563EB;color:#ffffff;'
            'border-radius:20px;padding:2px 10px;font-weight:bold;'
            'box-shadow: 0 4px 8px rgba(37,99,235,0.3);">'
            ' ($num) </span>';
      } else {
        return '<span style="color:#64748B;border:1px solid #E2E8F0;'
            'border-radius:6px;padding:0 6px;background:#EFF6FF;"> ($num) </span>';
      }
    });
  }

  Map<String, dynamic>? _parseAiData(QuestionModel q) {
    final result = <String, dynamic>{};

    // 1. Try to parse from structured JSON (New Format)
    if (q.passageTranslationData != null && q.passageTranslationData!.isNotEmpty) {
      try {
        final decoded = jsonDecode(q.passageTranslationData!);
        if (decoded is Map && decoded.containsKey('questions')) {
          final aiQs = decoded['questions'] as List;
          final aiQ = aiQs.firstWhere(
            (aq) => aq['questionNumber'] == q.questionNumber,
            orElse: () => null,
          );
          if (aiQ != null) {
            result['analysis'] = aiQ['analysis'] ?? '';
            result['evidence'] = aiQ['evidence'] ?? '';
            result['optionTranslations'] = aiQ['optionTranslations'] ?? {};
            
            // Vocabulary gộp từ toàn bộ group passage nếu có
            if (decoded.containsKey('vocabulary')) {
              result['vocabulary'] = decoded['vocabulary'];
            }
            return result;
          }
        }
      } catch (e) {
        debugPrint('Error parsing structured AI JSON: $e');
      }
    }

    // 2. Fallback to regex parsing from raw explanation string
    if (q.explanation == null || q.explanation!.isEmpty) return null;
    final text = q.explanation!;
    if (text.contains('📄 Dịch đoạn văn:') ||
        text.contains('📋 Dịch đáp án:')) {
      final ptMatch = RegExp(
        r'📄 Dịch đoạn văn:\n([\s\S]*?)(?=\n\n📋|\n📋|$)',
      ).firstMatch(text);
      if (ptMatch != null) {
        result['passageTranslation'] = ptMatch.group(1)?.trim() ?? '';
      }

      final optsMatch = RegExp(
        r'📋 Dịch đáp án:\n([\s\S]*?)(?=\n\n✏️|\n✏️|$)',
      ).firstMatch(text);
      if (optsMatch != null) {
        final optsBlock = optsMatch.group(1)?.trim() ?? '';
        final opts = <String, String>{};
        for (final label in ['A', 'B', 'C', 'D']) {
          final m = RegExp('$label\\. ([^\\n]+)').firstMatch(optsBlock);
          if (m != null) {
            opts[label] = m.group(1)?.replaceAll('  ✅', '').trim() ?? '';
          }
        }
        result['optionTranslations'] = opts;
      }

      final analysisMatch = RegExp(
        r'✏️ Phân tích:\n([\s\S]*)$',
      ).firstMatch(text);
      if (analysisMatch != null) {
        result['analysis'] = analysisMatch.group(1)?.trim() ?? '';
      }
      return result.isNotEmpty ? result : null;
    }
    return null;
  }

  Map<String, dynamic> _getPaletteColorInfo(int i, List<QuestionModel> questions) {
    final isActive = i == _activeIndex;
    final userAnswer = widget.userAnswers[questions[i].id];
    final isUnanswered = userAnswer == null || userAnswer.isEmpty;
    final isCorrect = userAnswer == questions[i].correctAnswer;

    if (isActive) {
      return {
        'bg': _primaryBlue,
        'border': _primaryBlue,
        'text': Colors.white,
      };
    }

    if (isUnanswered) {
      return {
        'bg': Colors.white,
        'border': AppColors.divider,
        'text': _slateSubtext,
      };
    }

    if (isCorrect) {
      return {
        'bg': AppColors.success.withValues(alpha: 0.1),
        'border': AppColors.success,
        'text': AppColors.success,
      };
    }

    return {
      'bg': AppColors.error.withValues(alpha: 0.1),
      'border': AppColors.error,
      'text': AppColors.error,
    };
  }

  void _showQuestionGrid(BuildContext context, List<QuestionModel> questions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(AppColors.success.withValues(alpha: 0.1), AppColors.success, 'Đúng'),
                  const SizedBox(width: 16),
                  _buildLegendItem(AppColors.error.withValues(alpha: 0.1), AppColors.error, 'Sai'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.white, AppColors.divider, 'Bỏ trống'),
                ],
              ),
              const SizedBox(height: 24),
              // Grid
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: questions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, i) {
                    final colorInfo = _getPaletteColorInfo(i, questions);
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorInfo['bg'],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorInfo['border'], width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: colorInfo['text'],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color bg, Color border, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: _slateSubtext)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions;
    final bool hasPassage = _rawPassage.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TOP: Passage viewer (Split-view with Draggable Divider)
            if (hasPassage) ...[
              Expanded(
                flex: (_topPaneFlex * 1000).toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: AppShadows.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _slateText),
                            ),
                            const Icon(Icons.article_outlined, color: _primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Đoạn văn Reading',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _slateText,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.grid_view_rounded, color: _primaryBlue, size: 20),
                              onPressed: () => _showQuestionGrid(context, questions),
                            ),
                          ],
                        ),
                      ),
                      // Passage Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _passageScrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: TouchablePassageWidget(
                            htmlContent: _buildPassageHtml(
                              questions.isNotEmpty ? questions[_activeIndex].questionNumber : 0,
                            ),
                            translations: questions[_activeIndex].passageTranslations,
                            textStyle: GoogleFonts.tinos(
                              fontSize: 18,
                              height: 1.8,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // DRAGGABLE DIVIDER (Handle bar)
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    double delta = details.primaryDelta! / MediaQuery.of(context).size.height;
                    _topPaneFlex = (_topPaneFlex + delta).clamp(0.2, 0.82);
                  });
                },
                child: Container(
                  height: 32,
                  width: double.infinity,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            if (!hasPassage)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _primaryBlue),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Xem lại đoạn văn',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _slateText,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.grid_view_rounded, color: _primaryBlue, size: 20),
                      onPressed: () => _showQuestionGrid(context, questions),
                    ),
                  ],
                ),
              ),

            // BOTTOM: Questions
            Expanded(
              flex: hasPassage ? ((1.0 - _topPaneFlex) * 1000).toInt() : 10,
              child: PageView.builder(
                controller: _pageController,
                itemCount: questions.length,
                onPageChanged: (i) {
                  final prev = widget.questions[_activeIndex].passage;
                  final next = widget.questions[i].passage;
                  setState(() => _activeIndex = i);
                  if (prev != next && _passageScrollController.hasClients) {
                    _passageScrollController.jumpTo(0);
                  }
                },
                itemBuilder: (context, index) => _buildQuestionCard(questions[index], index),
              ),
            ),

            // FOOTER: Palette & Navigation
            _buildFooter(questions),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, int index) {
    final userAnswer = widget.userAnswers[question.id];
    final isCorrect = userAnswer == question.correctAnswer;
    final aiData = _parseAiData(question);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.softShadow,
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Question Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Câu ${question.questionNumber}',
                  style: GoogleFonts.inter(
                    color: _primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (userAnswer == null || userAnswer.isEmpty)
                      ? Colors.grey.shade100
                      : (isCorrect ? Colors.green.shade50 : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      (userAnswer == null || userAnswer.isEmpty)
                          ? Icons.help_outline_rounded
                          : (isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded),
                      color: (userAnswer == null || userAnswer.isEmpty)
                          ? Colors.grey
                          : (isCorrect ? _emerald : _rose),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (userAnswer == null || userAnswer.isEmpty)
                          ? 'Bỏ trống'
                          : (isCorrect ? 'Đúng' : 'Sai'),
                      style: GoogleFonts.inter(
                        color: (userAnswer == null || userAnswer.isEmpty)
                            ? Colors.grey
                            : (isCorrect ? _emerald : _rose),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Text
          if (question.questionText?.isNotEmpty ?? false) ...[
            HtmlWidget(
              question.questionText!,
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _slateText,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Options Visualization
          _buildOptionsList(question, userAnswer, aiData),

          const SizedBox(height: 24),

          // AI Explanation Card
          _buildExplanationArea(question, index, isCorrect, aiData),
        ],
      ),
    );
  }

  Widget _buildExplanationArea(QuestionModel question, int index, bool isCorrect, Map<String, dynamic>? aiData) {
    final bool hasAIFeedback = widget.aiFeedbacks != null && index < widget.aiFeedbacks!.length;
    final bool hasExplanation = question.explanation?.isNotEmpty ?? false;

    if (!hasAIFeedback && !hasExplanation) return const SizedBox.shrink();

    return Column(
      children: [
        if (hasAIFeedback) _buildAIFeedbackCard(index),
        if (hasExplanation) ...[
          const SizedBox(height: 16),
          _buildAIExplanationCard(question, index, aiData),
        ],
      ],
    );
  }

  Widget _buildAIFeedbackCard(int index) {
    final feedback = widget.aiFeedbacks![index];
    if (feedback == null || feedback.toString().isEmpty) return const SizedBox.shrink();

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
                const SizedBox(height: 4),
                HtmlWidget(
                  feedback.toString(),
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

  Widget _buildOptionsList(QuestionModel q, String? userAnswer, Map<String, dynamic>? aiData) {
    final Map<String, String?> options = {
      'A': q.optionA,
      'B': q.optionB,
      'C': q.optionC,
      'D': q.optionD,
    };

    final optionTranslations = aiData?['optionTranslations'] as Map<String, dynamic>?;

    return Column(
      children: options.entries.map((entry) {
        final label = entry.key;
        final text = entry.value ?? '';
        final isCorrect = label == q.correctAnswer;
        final isSelected = label == userAnswer;
        final isWrongSelection = isSelected && !isCorrect;

        Color bgColor = Colors.white;
        Color borderColor = const Color(0xFFE2E8F0);
        Color textColor = _slateText;
        IconData? icon;
        Color iconColor = Colors.transparent;

        if (isCorrect) {
          bgColor = Colors.green.shade50;
          borderColor = _emerald;
          textColor = _emerald;
          icon = Icons.check_circle;
          iconColor = _emerald;
        } else if (isWrongSelection) {
          bgColor = Colors.red.shade50;
          borderColor = _rose;
          textColor = _rose;
          icon = Icons.close;
          iconColor = _rose;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: (isCorrect || isWrongSelection) ? 2 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$label. ',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 15,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (icon != null) Icon(icon, color: iconColor, size: 20),
                  ],
                ),
                if (optionTranslations != null && optionTranslations.containsKey(label))
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 22),
                    child: Text(
                      optionTranslations[label],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _slateSubtext,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAIExplanationCard(QuestionModel question, int index, Map<String, dynamic>? aiData) {
    final content = question.explanation;
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pastelBlueLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.2)),
        boxShadow: AppShadows.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Phân tích câu hỏi',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: _slateText,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: HtmlWidget(
              content,
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(List<QuestionModel> questions) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Palette
          SizedBox(
            height: 44,
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
                    width: 44,
                    decoration: BoxDecoration(
                      color: colorInfo['bg'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorInfo['border'],
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: colorInfo['text'],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Quay lại kết quả',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

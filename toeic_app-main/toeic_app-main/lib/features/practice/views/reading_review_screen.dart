import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../models/question_model.dart';
import 'widgets/touchable_passage_widget.dart';
import 'widgets/vocab_flashcard_panel.dart';

/// Unified "Smart Reader" review screen for Reading parts (Part 6 & 7).
/// Redesigned with "Pro Blue" EdTech Premium aesthetic.
class ReadingReviewScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final Map<String, String> userAnswers; // questionId → selectedOption
  final List<String> flaggedQuestions; // questionIds
  final Set<String>? correctQuestionIds;
  final Set<int>? correctQuestionNumbers; // 🟢 NEW: Fallback for duplicate tests
  final int partNumber;
  final List<dynamic>? aiFeedbacks;
  final String? overallFeedback;

  const ReadingReviewScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    this.flaggedQuestions = const [],
    this.correctQuestionIds,
    this.correctQuestionNumbers,
    required this.partNumber,
    this.aiFeedbacks,
    this.overallFeedback,
  });

  /// ✅ New: Static builder for reusability in PracticeResultScreen
  static Widget buildStaticExplanationCard({
    required BuildContext context,
    required QuestionModel question,
    required Map<String, dynamic>? aiData,
    required String? userAnswer,
  }) {
    // Fallback logic for parts 6/7
    final String? displayExplanation = (question.explanation != null && question.explanation!.isNotEmpty)
        ? question.explanation
        : question.fullPassageTranslation;
    
    // Determine if we should show the generic explanation block
    final bool showExplanation = displayExplanation != null && displayExplanation.isNotEmpty;

    final String? analysis = (question.analysis != null && question.analysis!.isNotEmpty)
        ? question.analysis
        : (aiData != null ? aiData['analysis'] : null);
    
    final String? evidence = (question.evidence != null && question.evidence!.isNotEmpty)
        ? question.evidence
        : (aiData != null ? aiData['evidence'] : null);

    final dynamic vocabulary = (aiData != null && aiData['vocabulary'] != null)
        ? aiData['vocabulary']
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Translation of Question
        if (question.questionTranslation != null && question.questionTranslation!.isNotEmpty) ...[
          _staticSectionHeader('Dịch câu hỏi', Icons.translate, const Color(0xFF6366F1)),
          Text(question.questionTranslation!, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
        ],

        // Analysis
        if (analysis != null && analysis.isNotEmpty) ...[
          _staticSectionHeader('Phân tích đáp án', Icons.psychology_outlined, AppColors.primary),
          Text(analysis, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.6)),
          const SizedBox(height: 16),
        ],

        // Evidence
        if (evidence != null && evidence.isNotEmpty) ...[
          _staticSectionHeader('Bằng chứng', Icons.fact_check_outlined, AppColors.success),
          Text(evidence, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontStyle: FontStyle.italic, height: 1.6)),
          const SizedBox(height: 16),
        ],

        // Generic Explanation (if other fields are empty or as summary)
        if (showExplanation && analysis == null) ...[
          _staticSectionHeader('Giải thích chi tiết', Icons.info_outline, const Color(0xFF64748B)),
          HtmlWidget(displayExplanation, textStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.6)),
          const SizedBox(height: 16),
        ],

        if (vocabulary is List && vocabulary.isNotEmpty) ...[
          const SizedBox(height: 8),
          VocabFlashcardPanel(
            vocabItems: vocabulary,
            partId: question.partId,
          ),
        ],

        // Audio Script (For Listening parts)
        if (question.transcript != null && question.transcript!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _staticSectionHeader('Audio Script', Icons.description_outlined, const Color(0xFF64748B)),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: HtmlWidget(
              question.transcript!,
              textStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF334155), height: 1.6),
            ),
          ),
        ],
      ],
    );
  }

  static Widget _staticSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

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
    final regex = RegExp(r'\[(\d+)\]');
    return _rawPassage.replaceAllMapped(regex, (match) {
      final numStr = match.group(1) ?? '';
      final questionNum = int.tryParse(numStr) ?? 0;
      final isActive = numStr == activeQuestionNumber.toString();

      // Find the question info to determine color
      final questionIndex = widget.questions.indexWhere((q) => q.questionNumber == questionNum);
      
      String bgColor = '#F1F5F9'; // Default Slate-50
      String textColor = '#475569'; // Slate-600
      String borderColor = '#CBD5E1'; // Slate-300
      String labelPrefix = '#';

      if (isActive) {
        bgColor = '#4F46E5'; // Indigo-600
        textColor = '#FFFFFF';
        borderColor = '#4F46E5';
        labelPrefix = 'Q';
      } else if (questionIndex != -1) {
        final q = widget.questions[questionIndex];
        // 🟢 Aggressive answer normalization
        String clean(String? s) {
          if (s == null || s.isEmpty) return '';
          final match = RegExp(r'[A-D]').firstMatch(s.trim().toUpperCase());
          return match?.group(0) ?? s.trim().toUpperCase();
        }

        final String? userAnswer = widget.userAnswers[q.id.trim()];
        bool isCorrect;
        if (widget.correctQuestionIds != null || widget.correctQuestionNumbers != null) {
          isCorrect = (widget.correctQuestionIds?.contains(q.id.trim()) ?? false) || 
                       (widget.correctQuestionNumbers?.contains(q.questionNumber) ?? false);
        } else {
          isCorrect = userAnswer != null &&
              clean(userAnswer) == clean(q.correctAnswer);
        }
        final isUnanswered = userAnswer == null || userAnswer.isEmpty;
        final isFlagged = widget.flaggedQuestions.contains(q.id);

        if (isCorrect) {
          bgColor = '#D1FAE5'; // Emerald-100 (Stronger contrast)
          textColor = '#065F46'; // Emerald-800
          borderColor = '#10B981'; // Emerald-500
        } else if (isFlagged) {
          bgColor = '#FFEDD5'; // Orange-100
          textColor = '#9A3412'; // Orange-800
          borderColor = '#F97316'; // Orange-500
        } else if (isUnanswered) {
          bgColor = '#FFFFFF';
          textColor = '#64748B'; // Slate-500
          borderColor = '#CBD5E1';
        } else {
          bgColor = '#FEE2E2'; // Rose-100
          textColor = '#991B1B'; // Rose-800
          borderColor = '#EF4444'; // Rose-500
        }
      }

      return '<span style="background: $bgColor; color: $textColor; '
          'border: 1px solid $borderColor; border-radius: 6px; padding: 2px 10px; '
          'font-weight: 700; display: inline-flex; align-items: center; '
          'justify-content: center; font-size: 13px; margin: 0 4px; '
          'font-family: sans-serif; transition: all 0.2s;">'
          '$labelPrefix$numStr</span>';
    });
  }

  Map<String, dynamic>? _parseAiData(QuestionModel q) {
    final result = <String, dynamic>{};

    // 1. Priority: Model Fields (New Format)
    if ((q.analysis != null && q.analysis!.isNotEmpty) || 
        (q.evidence != null && q.evidence!.isNotEmpty) ||
        (q.questionTranslation != null && q.questionTranslation!.isNotEmpty)) {
      result['analysis'] = q.analysis ?? '';
      result['evidence'] = q.evidence ?? '';
      result['questionTranslation'] = q.questionTranslation ?? '';
    }

    // Pass the full passage translation string if available
    final passageVi = q.fullPassageTranslation;
    if (passageVi.isNotEmpty) {
      result['passageTranslation'] = passageVi;
    }

    // Key Vocabulary from dedicated field
    if (q.keyVocabulary != null && q.keyVocabulary!.isNotEmpty) {
      try {
        final decoded = jsonDecode(q.keyVocabulary!);
        if (decoded is List) {
          result['vocabulary'] = decoded;
        } else if (decoded is Map && decoded.containsKey('vocabulary')) {
          result['vocabulary'] = decoded['vocabulary'] is List ? decoded['vocabulary'] : [];
        }
      } catch (e) {
        debugPrint('Error parsing keyVocabulary: $e');
      }
    }

    // Option Translations from dedicated field
    if (q.optionTranslations != null && q.optionTranslations!.isNotEmpty) {
      try {
        result['optionTranslations'] = jsonDecode(q.optionTranslations!);
      } catch (e) {
        debugPrint('Error parsing optionTranslations: $e');
      }
    }

    if (q.passageTranslationData != null && q.passageTranslationData!.isNotEmpty) {
      try {
        final decoded = jsonDecode(q.passageTranslationData!);
        // If we don't have analysis/evidence yet, try to get from structured data (backward compatibility)
        if (decoded is Map && decoded.containsKey('questions')) {
          final aiQs = decoded['questions'] as List;
          final aiQ = aiQs.firstWhere(
            (aq) => aq['questionNumber'] == q.questionNumber,
            orElse: () => null,
          );
          if (aiQ != null) {
            if (result['analysis'] == null || result['analysis'].isEmpty) result['analysis'] = aiQ['analysis'] ?? '';
            if (result['evidence'] == null || result['evidence'].isEmpty) result['evidence'] = aiQ['evidence'] ?? '';
            if (result['optionTranslations'] == null) result['optionTranslations'] = aiQ['optionTranslations'] ?? {};
            
            if (decoded.containsKey('vocabulary') && result['vocabulary'] == null) {
              result['vocabulary'] = decoded['vocabulary'];
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing structured AI JSON: $e');
      }
    }

    // If we have some rich data, we can stop here
    if (result.containsKey('analysis') && result['analysis'].isNotEmpty) return result;

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
  Map<String, dynamic> _getPaletteColorInfo(int i) {
    final isActive = i == _activeIndex;
    final q = widget.questions[i];
    final qId = q.id.trim();
    final userAnswer = widget.userAnswers[qId];
    final isUnanswered = userAnswer == null || userAnswer.trim().isEmpty;
    
    // 🟢 Aggressive answer normalization
    String clean(String? s) {
      if (s == null || s.isEmpty) return '';
      final match = RegExp(r'[A-D]').firstMatch(s.trim().toUpperCase());
      return match?.group(0) ?? s.trim().toUpperCase();
    }

    // Ưu tiên dùng dữ liệu từ bảng attempt_details nếu có (Dual-Check)
    bool isCorrect;
    if (widget.correctQuestionIds != null || widget.correctQuestionNumbers != null) {
      final inIdSet = widget.correctQuestionIds?.contains(qId) ?? false;
      final inNumSet = widget.correctQuestionNumbers?.contains(q.questionNumber) ?? false;
      isCorrect = inIdSet || inNumSet;
    } else {
      isCorrect = !isUnanswered && 
          clean(userAnswer) == clean(q.correctAnswer);
    }


    final isFlagged = widget.flaggedQuestions.contains(q.id);

    // Default styles (Bỏ trống)
    Map<String, dynamic> info = {
      'bg': Colors.white,
      'border': const Color(0xFFE2E8F0),
      'text': _slateSubtext,
      'activeBorder': Colors.transparent,
      'borderWidth': 1.5,
      'shadow': false,
    };

    if (isCorrect) {
      // Đúng (Xanh) - High Priority
      info['bg'] = AppColors.success.withValues(alpha: 0.2); // Increased visibility
      info['border'] = AppColors.success;
      info['text'] = AppColors.success;
      info['borderWidth'] = 2.0; // Thicker for status
    } else {
      // Sai hoặc Bỏ trống -> Đều tính là lỗi (Đỏ)
      info['bg'] = AppColors.error.withValues(alpha: 0.2); // Increased visibility
      info['border'] = AppColors.error;
      info['text'] = AppColors.error;
      info['borderWidth'] = 2.0; // Thicker for status
      
      // Ưu tiên hiển thị Cắm cờ nếu HV đánh dấu câu phân vân
      if (isFlagged) {
        info['bg'] = Colors.orange.withValues(alpha: 0.1);
        info['border'] = Colors.orange;
        info['text'] = Colors.orange;
      }
    }

    // Highlight Current
    if (isActive) {
      info['activeBorder'] = _primaryBlue;
      info['borderWidth'] = 3.5;
      info['shadow'] = true;
      if (info['bg'] == Colors.white) {
        info['bg'] = _primaryBlue.withValues(alpha: 0.1);
        info['text'] = _primaryBlue;
      }
    }

    return info;
  }

  void _showQuestionGrid(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(AppColors.success.withValues(alpha: 0.1), AppColors.success, 'Đúng'),
                  const SizedBox(width: 24),
                  _buildLegendItem(AppColors.error.withValues(alpha: 0.1), AppColors.error, 'Sai/Bỏ trống'),
                  const SizedBox(width: 24),
                  _buildLegendItem(Colors.orange.withValues(alpha: 0.1), Colors.orange, 'Cắm cờ'),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: widget.questions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, i) {
                    final colorInfo = _getPaletteColorInfo(i);
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
                          color: colorInfo['bg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (colorInfo['activeBorder'] as Color) != Colors.transparent 
                                ? (colorInfo['activeBorder'] as Color) 
                                : (colorInfo['border'] as Color), 
                            width: (colorInfo['borderWidth'] as num).toDouble(),
                          ),
                          boxShadow: colorInfo['shadow'] == true
                              ? [
                                  BoxShadow(
                                    color: _primaryBlue.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${widget.questions[i].questionNumber}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: colorInfo['text'] as Color,
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

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(AppLocalizations.of(context)?.translate('review') ?? 'Xem lại'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy dữ liệu câu hỏi.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đoạn văn Reading',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _slateText,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  if (widget.questions.isNotEmpty)
                                    Text(
                                      'Câu ${widget.questions.first.questionNumber} - ${widget.questions.last.questionNumber}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: _slateSubtext,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                             IconButton(
                               icon: const Icon(Icons.grid_view_rounded, color: _primaryBlue, size: 20),
                               onPressed: () => _showQuestionGrid(context),
                             ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _passageScrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _buildPassageContentView(questions.isNotEmpty ? questions[_activeIndex] : null),
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
                      onPressed: () => _showQuestionGrid(context),
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
                  final prev = widget.questions.elementAtOrNull(_activeIndex)?.passage;
                  final next = widget.questions.elementAtOrNull(i)?.passage;
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
    final qId = question.id.trim();
    final String? userAnswer = widget.userAnswers[qId];

    // 🟢 Aggressive answer normalization
    String clean(String? s) {
      if (s == null || s.isEmpty) return '';
      final match = RegExp(r'[A-D]').firstMatch(s.trim().toUpperCase());
      return match?.group(0) ?? s.trim().toUpperCase();
    }

    bool isCorrect;
    if (widget.correctQuestionIds != null || widget.correctQuestionNumbers != null) {
      isCorrect = (widget.correctQuestionIds?.contains(qId) ?? false) || 
                   (widget.correctQuestionNumbers?.contains(question.questionNumber) ?? false);
    } else {
      isCorrect = userAnswer != null &&
          clean(userAnswer) == clean(question.correctAnswer);
    }
    final aiData = _parseAiData(question);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.premiumShadow,
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Question Header
          if (index == 0 && widget.overallFeedback != null && widget.overallFeedback!.isNotEmpty)
             _buildOverallAssessmentCard(),

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
                  color: isCorrect 
                      ? _emerald.withValues(alpha: 0.1)
                      : _rose.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCorrect ? _emerald : _rose,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect 
                          ? Icons.check_circle_rounded 
                          : Icons.cancel_rounded,
                      color: isCorrect ? _emerald : _rose,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCorrect ? 'Đúng' : 'Sai',
                      style: GoogleFonts.inter(
                        color: isCorrect ? _emerald : _rose,
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
    
    // Check for ANY professional content from DB or AI data
    final bool hasExpertContent = (question.explanation?.isNotEmpty ?? false) ||
                                 (question.analysis?.isNotEmpty ?? false) ||
                                 (question.evidence?.isNotEmpty ?? false) ||
                                 (question.questionTranslation?.isNotEmpty ?? false) ||
                                 (question.keyVocabulary?.isNotEmpty ?? false) ||
                                 (aiData != null && (
                                   aiData.containsKey('analysis') ||
                                   aiData.containsKey('evidence') ||
                                   aiData.containsKey('vocabulary') ||
                                   aiData.containsKey('questionTranslation')
                                 ));

    if (!hasAIFeedback && !hasExpertContent) return const SizedBox.shrink();

    return Column(
      children: [
        if (hasAIFeedback) _buildAIFeedbackCard(index),
        if (hasExpertContent) ...[
          const SizedBox(height: 16),
          _buildAIExplanationCard(question, index, aiData),
        ],
      ],
    );
  }

  Widget _buildAIFeedbackCard(int index) {
    if (widget.aiFeedbacks == null) return const SizedBox.shrink();

    final currentQuestion = widget.questions[index];
    
    // Precise ID-based matching (UUID) - Fallback to questionNumber for legacy data
    final feedbackItem = widget.aiFeedbacks!.firstWhere(
      (f) => (f is Map && f['questionId'] == currentQuestion.id) ||
             (f is Map && f['id'] == currentQuestion.id) ||
             (f is Map && f['questionNumber'] == currentQuestion.questionNumber),
      orElse: () => null,
    );

    if (feedbackItem == null) return const SizedBox.shrink();
    
    final String comment = feedbackItem['comment'] ?? feedbackItem['tip'] ?? feedbackItem['feedback'] ?? feedbackItem.toString();
    if (comment.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Light Orange
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: AppShadows.softShadow,
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

  Map<String, dynamic> _parseOverallFeedback(String? feedback) {
    if (feedback == null || feedback.isEmpty) return {};
    try {
      if (feedback.trim().startsWith('{')) {
        return jsonDecode(feedback);
      }
      // Fallback if it's plain text
      return {'shortFeedback': feedback};
    } catch (e) {
      debugPrint('Error parsing overall feedback: $e');
      return {'shortFeedback': feedback};
    }
  }

  Widget _buildOverallAssessmentCard() {
    final data = _parseOverallFeedback(widget.overallFeedback);
    final String feedbackText = data['shortFeedback'] ?? data['assessment'] ?? data['recommendationText'] ?? widget.overallFeedback ?? '';
    final List<dynamic> strengths = data['strengths'] ?? [];
    final List<dynamic> weaknesses = data['weaknesses'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Orange Gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFFFF7ED), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TỔNG KẾT TỪ AI COACH',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF92400E),
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Phân tích chi tiết khả năng làm bài',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB45309),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (data['progressScore'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${data['progressScore']}%',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Feedback text
                HtmlWidget(
                  feedbackText,
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: const Color(0xFF451A03),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                if (strengths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('ĐIỂM MẠNH', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green.shade700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...strengths.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.toString(), style: GoogleFonts.inter(fontSize: 13, color: Colors.green.shade900))),
                      ],
                    ),
                  )),
                ],

                if (weaknesses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('CẦN CẢI THIỆN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange.shade700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...weaknesses.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 14, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(w.toString(), style: GoogleFonts.inter(fontSize: 13, color: Colors.orange.shade900))),
                      ],
                    ),
                  )),
                ],
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

    Map<String, dynamic>? optionTranslations;
    if (q.optionTranslations != null && q.optionTranslations!.isNotEmpty) {
      try {
        optionTranslations = jsonDecode(q.optionTranslations!);
      } catch (e) {
        debugPrint('Failed to parse optionTranslations: $e');
      }
    } else {
      optionTranslations = aiData?['optionTranslations'] as Map<String, dynamic>?;
    }

    return Column(
      children: options.entries.map((entry) {
        final label = entry.key;
        final text = entry.value ?? '';
        final bool isCorrect = label.trim().toUpperCase() == (q.correctAnswer ?? '').trim().toUpperCase();
        final bool isSelected = label.trim().toUpperCase() == (userAnswer ?? '').trim().toUpperCase();
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
                      optionTranslations[label].toString(),
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
    // Logic to handle explanation fallback for Part 6/7.
    // We use fullPassageTranslation if question.explanation is empty.
    String? displayExplanation = (question.explanation != null && question.explanation!.isNotEmpty)
        ? question.explanation
        : (widget.partNumber == 6 || widget.partNumber == 7) ? question.fullPassageTranslation : null;

    // Priority: New DB field -> aiData fallback -> null
    final String? analysis = (question.analysis != null && question.analysis!.isNotEmpty)
        ? question.analysis
        : (aiData != null && aiData['analysis'] != null) ? aiData['analysis'] : null;
        
    final String? evidence = (question.evidence != null && question.evidence!.isNotEmpty)
        ? question.evidence
        : (aiData != null && aiData['evidence'] != null) ? aiData['evidence'] : null;

    final String? questionTranslation = (question.questionTranslation != null && question.questionTranslation!.isNotEmpty)
        ? question.questionTranslation
        : null;

    List<dynamic>? vocabulary;
    if (question.keyVocabulary != null && question.keyVocabulary!.isNotEmpty) {
      try {
        vocabulary = jsonDecode(question.keyVocabulary!);
      } catch (e) {
        debugPrint('Failed to parse keyVocabulary: $e');
      }
    } else {
      vocabulary = aiData?['vocabulary'] as List<dynamic>?;
    }

    if (displayExplanation == null && analysis == null && evidence == null && vocabulary == null && questionTranslation == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // 0. Question Translation
        if (questionTranslation != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.translate_rounded, color: Color(0xFF475569), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Dịch câu hỏi',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  questionTranslation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: const Color(0xFF334155),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        // 1. Analysis Card
        if (analysis != null && analysis.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: _primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Phân tích chuyên sâu',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  analysis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: _slateText,
                  ),
                ),
              ],
            ),
          ),

        // 2. Evidence Card
        if (evidence != null && evidence.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: _emerald, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Bằng chứng trong bài',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: _emerald,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  evidence,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: _slateText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        if (vocabulary != null && vocabulary.isNotEmpty) ...[
          const SizedBox(height: 10),
          VocabFlashcardPanel(
            vocabItems: vocabulary,
            partId: question.partId,
            onAllSwiped: () {
              final questions = widget.questions;
              if (index < questions.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],

      ],
    );
  }

  // ── Smart View Switcher ──────────────────────────────────────────────────

  Widget _buildPassageContentView(QuestionModel? q) {
    if (q == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title (if any)
        if (q.passageTitle != null && q.passageTitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              q.passageTitle!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _primaryBlue,
                letterSpacing: 0.5,
              ),
            ),
          ),

        // 2. Content: Smart Reader (Touchable Passage)
        TouchablePassageWidget(
          htmlContent: _buildPassageHtml(q.questionNumber),
          translations: q.passageTranslations,
          showAllTranslations: false,
          textStyle: GoogleFonts.tinos(
            fontSize: 18,
            height: 1.8,
            color: const Color(0xFF334155),
          ),
        ),
      ],
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
                final colorInfo = _getPaletteColorInfo(i);
                
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
                      color: colorInfo['bg']!,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (colorInfo['activeBorder'] as Color) != Colors.transparent 
                            ? (colorInfo['activeBorder'] as Color) 
                            : (colorInfo['border'] as Color), 
                        width: (colorInfo['borderWidth'] as num).toDouble(),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${questions[i].questionNumber}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: colorInfo['text']!,
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


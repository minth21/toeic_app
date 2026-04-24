import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../viewmodels/practice_viewmodel.dart';
import '../models/part_model.dart';
import 'part1_simulation_screen.dart';
import 'part2_simulation_screen.dart';
import 'test_simulation_screen.dart';
import 'reading_review_screen.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import 'listening_simulation_screen.dart';
import 'widgets/vocab_flashcard_panel.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../home/viewmodels/dashboard_viewmodel.dart';
import 'class_feedback_screen.dart';


class PracticeResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;
  final PartModel part;
  final String attemptId;
  final bool fromSimulation;

  const PracticeResultScreen({
    super.key,
    required this.resultData,
    required this.part,
    required this.attemptId,
    this.fromSimulation = false,
  });

  @override
  State<PracticeResultScreen> createState() => _PracticeResultScreenState();
}

class _PracticeResultScreenState extends State<PracticeResultScreen> {
  bool _isAnalyzing = true;
  Map<String, dynamic>? _aiData;
  bool _isLoadingDetail = false;
  List<Map<String, dynamic>> _recommendations = [];
  Map<String, dynamic>? _attemptDetail;
  final ScrollController _aiScrollController = ScrollController();
  String _loadingMessage = 'AI đang tổng hợp kết quả...';

  @override
  void initState() {
    super.initState();
    _fetchAIData();
    _fetchAttemptMetadata(); // 🔥 Fetch questions/vocab immediately
    _fetchRecommendations();
    _startLoadingTimer();
  }

  void _startLoadingTimer() {
    int seconds = 0;
    const messages = [
      'Đang tổng hợp kết quả...',
      'Đang dò tìm bộ lọc kiến thức...',
      'Gia sư AI đang viết nhận xét chi tiết...',
      'Sắp xong rồi, chờ một chút nhé...',
      'Đang tối ưu lộ trình học tập cho bạn...',
    ];

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted || !_isAnalyzing) return false;
      setState(() {
        seconds += 4;
        int index = (seconds ~/ 4) % messages.length;
        _loadingMessage = messages[index];
      });
      return true;
    });
  }

  Future<void> _fetchRecommendations() async {
    final viewModel = context.read<PracticeViewModel>();
    final recs = await viewModel.getDailyRecommendations();
    if (mounted) {
      setState(() {
        _recommendations = recs;
      });
    }
  }

  Future<void> _fetchAIData() async {
    // Keep internal analytics as is, but we'll complement with local metadata
    setState(() => _isAnalyzing = true);
    final viewModel = context.read<PracticeViewModel>();
    final data = await viewModel.pollAIAssessment(widget.attemptId);

    if (mounted) {
      setState(() {
        if (data != null) {
          try {
            final decodedAi = jsonDecode(data) as Map<String, dynamic>;
            // Merge AI data but preserve local vocab if it came in first
            if (_aiData != null &&
                _aiData!['vocabularyFlashcards'] != null &&
                (decodedAi['vocabularyFlashcards'] == null ||
                    (decodedAi['vocabularyFlashcards'] as List).isEmpty)) {
              decodedAi['vocabularyFlashcards'] =
                  _aiData!['vocabularyFlashcards'];
            }
            _aiData = decodedAi;
          } catch (e) {
            debugPrint('Error parsing AI data: $e');
          }
        }
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _fetchAttemptMetadata() async {
    try {
      final viewModel = context.read<PracticeViewModel>();
      final attempt = await viewModel.loadAttemptDetail(widget.attemptId);

      if (attempt != null && mounted) {
        _processAttemptDetails(attempt['details'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading early metadata: $e');
    }
  }

  void _processAttemptDetails(List<dynamic> details) {
    if (!mounted) return;

    final List<dynamic> aggregatedVocab = [];
    final List<Map<String, dynamic>> wrongQuestions = [];
    final Set<String> seenWords = {};

    for (var d in details) {
      if (d['question'] == null) continue;
      final qMap = Map<String, dynamic>.from(d['question'] as Map);
      
      // Robust ID extraction
      final String qId = (d['questionId'] ?? d['question_id'] ?? qMap['id'] ?? '').toString().trim();
      qMap['id'] = qId;

      // 1. Process wrong questions
      // ROBUST PARSING (String, Num, Bool)
      bool parseBool(dynamic v) {
        if (v == null) return false;
        if (v is bool) return v;
        if (v is num) return v == 1;
        final s = v.toString().toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'yes';
      }
      
      final bool isCorrect = parseBool(d['isCorrect'] ?? d['is_correct']);
      
      final String userAnswer = (d['userAnswer'] ?? d['user_answer'] ?? d['selectedOption'] ?? '').toString();

      if (!isCorrect) {
        wrongQuestions.add({'question': qMap, 'userAnswer': userAnswer});
      }

      // 2. Aggregate keyVocabulary
      final rawKeyVocab = qMap['keyVocabulary'];
      if (rawKeyVocab != null &&
          rawKeyVocab.toString().isNotEmpty &&
          rawKeyVocab.toString() != '[]') {
        try {
          final decoded = (rawKeyVocab is String)
              ? jsonDecode(rawKeyVocab)
              : rawKeyVocab;

          List<dynamic> vocabItems = [];
          if (decoded is List) {
            vocabItems = decoded;
          } else if (decoded is Map && decoded.containsKey('vocabulary')) {
            vocabItems = decoded['vocabulary'] is List
                ? decoded['vocabulary']
                : [];
          }

          for (var v in vocabItems) {
            if (v is! Map) continue;
            final word = (v['word'] ?? v['text'] ?? '').toString();
            if (word.isNotEmpty && !seenWords.contains(word.toLowerCase())) {
              v['ipa'] = v['ipa'] ?? v['pronunciation'];
              aggregatedVocab.add(v);
              seenWords.add(word.toLowerCase());
            }
          }
        } catch (e) {
          debugPrint('Error parsing keyVocabulary: $e');
        }
      }
    }

    setState(() {
      _attemptDetail = {'details': details}; // Store for review screen

      // Seed _aiData with local vocab immediately so it shows up before AI finishes
      if (_aiData == null) {
        _aiData = {
          'vocabularyFlashcards': aggregatedVocab,
          'wrongQuestions': wrongQuestions,
        };
      } else {
        _aiData!['wrongQuestions'] = wrongQuestions.isNotEmpty 
            ? wrongQuestions 
            : (_aiData?['wrongQuestions'] ?? []);
            
        final List? currentVocab = _aiData?['vocabularyFlashcards'] as List?;
        if ((currentVocab == null || currentVocab.isEmpty) && aggregatedVocab.isNotEmpty) {
          _aiData?['vocabularyFlashcards'] = aggregatedVocab;
        } else if (aggregatedVocab.isNotEmpty) {
          _aiData?['vocabularyFlashcards'] = aggregatedVocab;
        }
      }
    });
  }

  @override
  void dispose() {
    _aiScrollController.dispose();
    super.dispose();
  }

  void _onBack() {
    // Refresh dashboard to show new scores/progress
    try {
      context.read<DashboardViewModel>().loadDashboard();
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
    }

    if (widget.fromSimulation) {
      // Return to exercise list (Lùi 2 lần: Result -> Detail -> List)
      Navigator.pop(context); // Bỏ qua trang này
      Navigator.pop(context); // Quay về trang danh sách
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int score = widget.resultData['score'] ?? 0;
    final int total =
        widget.resultData['totalQuestions'] ?? widget.resultData['total'] ?? 0;
    final int toeicScore = widget.resultData['toeicScore'] ?? 0;
    final double percentage = total > 0 ? (score / total) * 100 : 0;
    final bool isListening = widget.part.partNumber <= 4;
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Cuộn mượt mà hơn
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row - Tự phẳng hóa
              Row(
                children: [
                  IconButton(
                    onPressed: _onBack,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text(
                    'Kết quả luyện tập',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Score Area
              _buildScoreHeader(score, total, percentage, toeicScore),
              const SizedBox(height: 24),
              
              // Spreads all analysis widgets directly into main Column
              ..._buildAnalysisContentList(isListening),
              
              const SizedBox(height: 16),
              
              // Topic Stats Area flattened - REMOVED per user request
              if (_isLoadingDetail)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                
              const SizedBox(height: 160), // Khoảng đệm rộng rãi để không bao giờ bị che
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(user?.classId),
    );
  }

  Widget _buildBottomActions(String? classId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Nút Danh sách (Icon only or small)
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.list_alt_rounded, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _handleReview,
                    icon: _isLoadingDetail
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.visibility_rounded, size: 18),
                    label: Text(
                      _isLoadingDetail ? 'TẢI...' : 'LỜI GIẢI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _showRetryConfirmation,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'LÀM LẠI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (classId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClassFeedbackScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text(
                  'Ý KIẾN GIÁO VIÊN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreHeader(
    int score,
    int total,
    double percentage,
    int toeicScore,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.premiumShadow,
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 8,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 80
                            ? Colors.green
                            : (percentage >= 50
                                  ? AppColors.primary
                                  : Colors.orange),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${percentage.toInt()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: percentage >= 80
                              ? Colors.green
                              : (percentage >= 50
                                    ? AppColors.primary
                                    : Colors.orange),
                        ),
                      ),
                      Text(
                        'Đúng',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Kết quả',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score/$total',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssessmentShimmer() {
    return Container(
      key: const ValueKey('ai_shimmer'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.softShadow,
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _loadingMessage,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnalysisContentList(bool isListening) {
    final skills =
        _aiData?['skills'] ??
        {'grammar': 5, 'vocabulary': 5, 'inference': 5, 'mainIdea': 5};

    return [
      if (!isListening) ...[
        _buildSectionTitle('Phân tích kỹ năng'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.softShadow,
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 220),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  gridBorderData: const BorderSide(
                    color: Colors.grey,
                    width: 0.5,
                  ),
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  dataSets: [
                    RadarDataSet(
                      fillColor: AppColors.primary.withValues(alpha: 0.3),
                      borderColor: AppColors.primary,
                      entryRadius: 3,
                      dataEntries: [
                        RadarEntry(value: (skills['grammar'] ?? 0).toDouble()),
                        RadarEntry(
                          value: (skills['vocabulary'] ?? 0).toDouble(),
                        ),
                        RadarEntry(
                          value: (skills['inference'] ?? 0).toDouble(),
                        ),
                        RadarEntry(value: (skills['mainIdea'] ?? 0).toDouble()),
                      ],
                    ),
                  ],
                  getTitle: (index, angle) {
                    switch (index) {
                      case 0:
                        return RadarChartTitle(text: 'Ngữ pháp', angle: angle);
                      case 1:
                        return RadarChartTitle(text: 'Từ vựng', angle: angle);
                      case 2:
                        return RadarChartTitle(text: 'Suy luận', angle: angle);
                      case 3:
                        return RadarChartTitle(text: 'Ý chính', angle: angle);
                      default:
                        return const RadarChartTitle(text: '');
                    }
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],

      if (_aiData?['strengths'] != null ||
          _aiData?['weaknesses'] != null) ...[
        _buildStrengthsWeaknesses(
          _aiData?['strengths'],
          _aiData?['weaknesses'],
        ),
        const SizedBox(height: 24),
      ],
      
      _buildSectionTitle('Nhận xét từ AI'),
      const SizedBox(height: 12),
      
      _isAnalyzing
          ? _buildAIAssessmentShimmer()
          : Container(
              key: const ValueKey('ai_result_container'),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.softShadow,
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: _aiData == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'AI đang bận hoặc cần thêm thời gian để phân tích bài làm của bạn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _fetchAIData,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Thử tải lại'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_aiData?['shortFeedback'] != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.indigo50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: HtmlWidget(
                                    (_aiData?['shortFeedback']?.toString() ?? "").isEmpty
                                        ? "AI đang tổng hợp đánh giá chi tiết cho bạn..."
                                        : _aiData!['shortFeedback'].toString(),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                      fontStyle: FontStyle.italic,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        HtmlWidget(
                          (_aiData?['detailedAssessment'] ??
                                  '<p>Hệ thống ghi nhận kết quả bài làm thành công.</p>')
                              .toString(),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            height: 1.8,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
            ),

      if (_aiData?['wrongQuestions'] != null &&
          (_aiData?['wrongQuestions'] as List).isNotEmpty) ...[
        const SizedBox(height: 32),
        _buildQuickReviewPortal(_aiData?['wrongQuestions'] as List),
      ],

      if (_aiData?['vocabularyFlashcards'] != null &&
          (_aiData?['vocabularyFlashcards'] as List).isNotEmpty) ...[
        const SizedBox(height: 40),
        _buildVocabularySection(_aiData?['vocabularyFlashcards'] as List),
      ],

      if (_recommendations.isNotEmpty) ...[
        const SizedBox(height: 40),
        _buildRecommendationsSection(),
      ],
    ];
  }

  Widget _buildStrengthsWeaknesses(dynamic strengths, dynamic weaknesses) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildBadgeList('Điểm mạnh', strengths ?? [], Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBadgeList(
            'Cần cải thiện',
            weaknesses ?? [],
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeList(String title, List<dynamic> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color.withValues(alpha: 0.8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: HtmlWidget(
              item.toString(),
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVocabularySection(List<dynamic> vocabItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VocabFlashcardPanel(
          vocabItems: vocabItems,
          partId: widget.part.id,
          onAllSwiped: null, // No auto-advance on result page
        ),
      ],
    );
  }

  void _showRetryConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Làm lại bài thi?'),
          ],
        ),
        content: const Text(
          'Hệ thống sẽ làm mới toàn bộ câu trả lời để bạn bắt đầu lượt thi mới. Mọi lượt làm bài trước đó vẫn được lưu lại trong lịch sử.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _handleRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRetry() async {
    final viewModel = context.read<PracticeViewModel>();

    // Navigate back to simulation screen
    if (widget.part.partNumber == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Part1SimulationScreen(
            test: viewModel.currentTest!,
            partId: widget.part.id,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestSimulationScreen(
            test: viewModel.currentTest!,
            partId: widget.part.id,
          ),
        ),
      );
    }
  }

  Future<void> _handleReview({String? filterTopic}) async {
    if (_isLoadingDetail) return;

    // Check if we already have the details loaded early
    List<dynamic> details;
    if (_attemptDetail != null) {
      details = _attemptDetail!['details'] ?? [];
    } else {
      setState(() => _isLoadingDetail = true);
      try {
        final viewModel = context.read<PracticeViewModel>();
        final attempt = await viewModel.loadAttemptDetail(widget.attemptId);
        if (attempt == null) {
          if (mounted) setState(() => _isLoadingDetail = false);
          return;
        }
        details = attempt['details'] ?? [];
        _processAttemptDetails(details); // Sync stats/vocab if not done
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingDetail = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
        }
        return;
      }
    }

    if (details.isNotEmpty && mounted) {
      final viewModel = context.read<PracticeViewModel>();
      try {
        // 1. Build robust userAnswers map and correctQuestionIds Set
        final Map<String, String> userAnswers = {};
        final Set<String> correctQuestionIds = {};
        final Set<int> correctQuestionNumbers = {};
        
        for (var d in details) {
          // Precise ID extraction helper
          final String qId = (d['questionId'] ?? d['question_id'] ?? (d['question'] != null ? d['question']['id'] : '')).toString().trim();
          if (qId.isEmpty) continue;
          
          final qMap = d['question'] as Map<String, dynamic>?;
          
          // ROBUST NUMBER EXTRACTION
          int parseInt(dynamic value) {
            if (value == null) return -1;
            if (value is int) return value;
            return int.tryParse(value.toString()) ?? -1;
          }
          final int qNum = parseInt(qMap?['questionNumber'] ?? qMap?['question_number'] ?? qMap?['number']);
          
          // Answer extraction
          String answer = (d['userAnswer'] ?? d['user_answer'] ?? d['selectedOption'] ?? '').toString().trim();
          
          // isCorrect check
          // isCorrect check - ROBUST PARSING (String, Num, Bool)
          bool parseBool(dynamic v) {
            if (v == null) return false;
            if (v is bool) return v;
            if (v is num) return v == 1;
            final s = v.toString().toLowerCase().trim();
            return s == 'true' || s == '1' || s == 'yes';
          }
          final bool isCorrect = parseBool(d['isCorrect'] ?? d['is_correct']);
          if (isCorrect) {
            correctQuestionIds.add(qId);
            if (qNum != -1 && qNum != 0) {
              correctQuestionNumbers.add(qNum);
            }
            
            // Fallback: If backend says correct but no answer, suggest the correctAnswer
            if (answer.isEmpty) {
              answer = (qMap?['correctAnswer'] ?? qMap?['correct_answer'] ?? '').toString().trim();
            }
          }
          
          userAnswers[qId] = answer;
        }


        // 2. Map questions using the SAME ID extraction and defensive filtering
        final List<QuestionModel> questions = details
            .where((d) {
              final qMap = d['question'] as Map<String, dynamic>?;
              if (qMap == null) return false;
              
              if (filterTopic == null) return true;
              final tag = qMap['topic_tag'] ?? 'Tổng quát';
              return tag == filterTopic;
            })
            .map((d) {
              final qMap = Map<String, dynamic>.from(d['question'] as Map);
              qMap['id'] = (d['questionId'] ?? d['question_id'] ?? qMap['id'] ?? '').toString().trim();
              return QuestionModel.fromJson(qMap);
            })
            .toList();

        // 3. Extract Test safely from attempt metadata if available
        final testData = widget.resultData['test'] ?? (widget.resultData.containsKey('details') ? widget.resultData['test'] : null);
        final practiceTest = testData != null ? ExamModel.fromJson(Map<String, dynamic>.from(testData as Map)) : viewModel.currentTest;

        if (widget.part.partNumber == 1) {
          if (practiceTest == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không tìm thấy dữ liệu đề thi.')),
              );
            }
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Part1SimulationScreen(
                test: practiceTest,
                partId: widget.part.id,
                isReviewMode: true,
                initialUserAnswers: userAnswers,
                correctQuestionIds: correctQuestionIds,
                correctQuestionNumbers: correctQuestionNumbers, // 🟢 Dual-Check
                aiFeedbacks: _aiData?['questionFeedbacks'],
              ),
            ),
          );
        } else if (widget.part.partNumber == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Part2SimulationScreen(
                questions: questions,
                isReviewMode: true,
                userAnswers: userAnswers,
                correctQuestionIds: correctQuestionIds,
                correctQuestionNumbers: correctQuestionNumbers, // 🟢 Dual-Check
                aiFeedbacks: _aiData?['questionFeedbacks'],
                partAudioUrl: widget.part.audioUrl,
              ),
            ),
          );
        } else if (widget.part.partNumber == 3 || widget.part.partNumber == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListeningSimulationScreen(
                test: practiceTest!,
                partId: widget.part.id,
                isReviewMode: true,
                initialUserAnswers: userAnswers,
                correctQuestionIds: correctQuestionIds,
                correctQuestionNumbers: correctQuestionNumbers,
                aiFeedbacks: _aiData?['questionFeedbacks'],
                overallFeedback: _aiData?['overallAssessment'],
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReadingReviewScreen(
                questions: questions,
                userAnswers: userAnswers,
                flaggedQuestions: (widget.resultData['flaggedQuestions'] as List?)?.cast<String>() ?? [],
                correctQuestionIds: correctQuestionIds,
                correctQuestionNumbers: correctQuestionNumbers, // 🟢 Dual-Check
                partNumber: widget.part.partNumber,
                aiFeedbacks: _aiData?['questionFeedbacks'],
                overallFeedback: _aiData?['overallAssessment'],
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error navigating to review: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không thể mở xem lại: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoadingDetail = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Lộ trình gợi ý'),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final rec = _recommendations[index];
              return _buildRecommendationCard(rec);
            },
          ),
        ),
      ],
    );
  }



  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    return GestureDetector(
      onTap: () => _handleRecommendationTap(rec),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16, bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.indigo50.withValues(alpha: 0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.softShadow,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Part ${rec['partNumber']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rec['title'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              rec['testTitle'] ?? '',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${rec['totalQuestions']} câu',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReviewPortal(List<dynamic> wrongItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ôn tập câu sai'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.softShadow,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: wrongItems.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (context, index) {
              final item = wrongItems[index];
              final q = QuestionModel.fromJson(item['question']);
              final userAnswer = item['userAnswer']?.toString() ?? '';

              return ListTile(
                onTap: () => _showQuickReviewModal(q, userAnswer),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${q.questionNumber}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      q.topicTag ?? 'Câu hỏi ${q.questionNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SAI',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  userAnswer.isEmpty 
                    ? 'Bạn chưa chọn đáp án cho câu này' 
                    : 'Bạn chọn: $userAnswer — Đáp án đúng: ${q.correctAnswer}',
                  style: TextStyle(
                    fontSize: 12,
                    color: userAnswer.isEmpty ? AppColors.error : AppColors.textSecondary,
                    fontWeight: userAnswer.isEmpty ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showQuickReviewModal(QuestionModel q, String userAnswer) {
    final aiData = _parseAiData(q);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Câu hỏi ${q.questionNumber}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ReadingReviewScreen.buildStaticExplanationCard(
                        context: context,
                        question: q,
                        aiData: aiData,
                        userAnswer: userAnswer,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for generic explanation block (could be refactored into ReadingReviewScreen)
  Map<String, dynamic>? _parseAiData(QuestionModel q) {
    final result = <String, dynamic>{};
    if (q.analysis != null && q.analysis!.isNotEmpty) {
      result['analysis'] = q.analysis;
    }
    if (q.evidence != null && q.evidence!.isNotEmpty) {
      result['evidence'] = q.evidence;
    }
    if (q.keyVocabulary != null && q.keyVocabulary!.isNotEmpty) {
      try {
        final decoded = jsonDecode(q.keyVocabulary!);
        result['vocabulary'] = decoded is List
            ? decoded
            : decoded['vocabulary'];
      } catch (_) {}
    }
    return result;
  }

  Future<void> _handleRecommendationTap(Map<String, dynamic> rec) async {
    final partId = rec['id'];
    if (partId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final viewModel = context.read<PracticeViewModel>();
      await viewModel.loadQuestions(partId);

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Find the full part object from the test if possible,
        // or we need a way to navigate to test detail first.
        // For now, let's assume we can navigate to Part1Simulation or TestSimulation.
        // But we need the PartModel object.

        // Simple strategy: reload all tests and find the part
        await viewModel.loadTests();
        PartModel? targetPart;
        for (var test in viewModel.tests) {
          for (var p in test.parts) {
            if (p.id == partId) {
              targetPart = p;
              break;
            }
          }
        }

        if (targetPart != null && mounted) {
          // Navigate to Test Simulation (which handles instructions etc.)
          // We need to import test_detail_screen or just push simulation directly
          // but TestDetailScreen is better for starting a new attempt.
          final test = viewModel.tests.firstWhere(
            (t) => t.parts.any((p) => p.id == partId),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TestSimulationScreen(test: test, partId: partId),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}

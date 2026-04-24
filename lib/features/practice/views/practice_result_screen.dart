import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../viewmodels/practice_viewmodel.dart';
import '../models/part_model.dart';
import 'reading_review_screen.dart';
import 'part1_simulation_screen.dart';
import 'part2_simulation_screen.dart';
import 'test_simulation_screen.dart';
import '../models/question_model.dart';
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
  Map<String, Map<String, int>> _topicStats = {}; // topic -> {correct, total}
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
      await Future.delayed(const Duration(seconds: 8));
      if (!mounted || !_isAnalyzing) return false;
      setState(() {
        seconds += 8;
        int index = (seconds ~/ 8) % messages.length;
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

    final Map<String, Map<String, int>> stats = {};
    final List<dynamic> aggregatedVocab = [];
    final List<Map<String, dynamic>> wrongQuestions = [];
    final Set<String> seenWords = {};

    for (var d in details) {
      final qMap = Map<String, dynamic>.from(d['question'] as Map);
      qMap['id'] = d['questionId']?.toString() ?? '';

      // 1. Parse topic stats
      final tag = qMap['topic_tag'] ?? qMap['topicTag'] ?? 'Tổng quát';
      final String correctAnswer = (qMap['correctAnswer'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final String userAnswer = (d['userAnswer'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final isCorrect = d['isCorrect'] ?? (userAnswer != '' && userAnswer == correctAnswer);

      if (!isCorrect) {
        wrongQuestions.add({'question': qMap, 'userAnswer': userAnswer});
      }

      if (!stats.containsKey(tag)) {
        stats[tag] = {'correct': 0, 'total': 0};
      }
      stats[tag]!['total'] = stats[tag]!['total']! + 1;
      if (isCorrect) {
        stats[tag]!['correct'] = stats[tag]!['correct']! + 1;
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
      _topicStats = stats;
      _attemptDetail = {'details': details}; // Store for review screen

      // Seed _aiData with local vocab immediately so it shows up before AI finishes
      if (_aiData == null) {
        _aiData = {
          'vocabularyFlashcards': aggregatedVocab,
          'wrongQuestions': wrongQuestions,
        };
      } else {
        _aiData!['wrongQuestions'] = wrongQuestions;
        final List currentVocab =
            (_aiData!['vocabularyFlashcards'] as List?) ?? [];
        if (currentVocab.isEmpty && aggregatedVocab.isNotEmpty) {
          _aiData!['vocabularyFlashcards'] = aggregatedVocab;
        } else if (aggregatedVocab.isNotEmpty) {
          _aiData!['vocabularyFlashcards'] = aggregatedVocab;
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
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _onBack,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                    Text(
                      'Kết quả luyện tập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildScoreHeader(score, total, percentage, toeicScore),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  child: _buildAnalysisContent(isListening),
                ),
                const SizedBox(height: 16),
                if (_isLoadingDetail)
                  const CircularProgressIndicator()
                else if (_topicStats.isNotEmpty)
                  _buildTopicStatsSection(),
                const SizedBox(height: 16),
                _buildActionButtons(user?.classId),
                const SizedBox(height: 16), // Bottom padding
              ],
            ),
          ),
        ),
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

  Widget _buildAnalysisContent(bool isListening) {
    final skills =
        _aiData?['skills'] ??
        {'grammar': 5, 'vocabulary': 5, 'inference': 5, 'mainIdea': 5};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isListening) ...[
          _buildSectionTitle('Phân tích kỹ năng'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.softShadow,
            ),
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
                    fontSize: 10, // Reduced from 11
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
          const SizedBox(height: 16),
        ],

        if (_aiData?['strengths'] != null ||
            _aiData?['weaknesses'] != null) ...[
          _buildStrengthsWeaknesses(
            _aiData?['strengths'],
            _aiData?['weaknesses'],
          ),
          const SizedBox(height: 16),
        ],
        _buildSectionTitle('Nhận xét từ AI'),
        const SizedBox(height: 8),
        _isAnalyzing
            ? _buildAIAssessmentShimmer()
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppShadows.softShadow,
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: _aiData == null
                    ? Column(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_aiData?['shortFeedback'] != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.indigo50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      (_aiData!['shortFeedback']?.toString() ??
                                                  "")
                                              .isEmpty
                                          ? "AI đang tổng hợp đánh giá chi tiết cho bạn..."
                                          : _aiData!['shortFeedback']
                                                .toString(),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
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
                          const SizedBox(height: 4),

                          // Quick Action: View Detailed Explanation
                        ],
                      ),
              ),
        if (_aiData?['wrongQuestions'] != null &&
            (_aiData?['wrongQuestions'] as List).isNotEmpty) ...[
          const SizedBox(height: 24),
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
      ],
    );
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
            child: Text(
              item.toString(),
              style: TextStyle(
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
        _buildSectionTitle('Từ vựng cần nhớ'),
        const SizedBox(height: 16),
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
        content: Text(
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
        final List<QuestionModel> questions = details
            .where((d) {
              if (filterTopic == null) return true;
              final qMap = d['question'] as Map<String, dynamic>;
              final tag = qMap['topic_tag'] ?? 'Tổng quát';
              return tag == filterTopic;
            })
            .map((d) {
              final qMap = Map<String, dynamic>.from(d['question'] as Map);
              qMap['id'] = d['questionId']?.toString() ?? '';
              return QuestionModel.fromJson(qMap);
            })
            .toList();

        final Map<String, String> userAnswers = {};
        final Map<String, bool> correctStatus = {};
        for (var d in details) {
          final qId = d['questionId'].toString();
          userAnswers[qId] = d['userAnswer'] ?? '';
          correctStatus[qId] = d['isCorrect'] ?? false;
        }

        if (widget.part.partNumber == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Part1SimulationScreen(
                test: viewModel.currentTest!,
                partId: widget.part.id,
                isReviewMode: true,
                initialUserAnswers: userAnswers,
                correctStatus: correctStatus,
                aiFeedbacks: _aiData?['questionFeedbacks'],
                overallFeedback: _aiData?['detailedAssessment'],
              ),
            ),
          );
        } else if (widget.part.partNumber == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Part2SimulationScreen(
                questions: questions,
                partAudioUrl: widget.part.audioUrl,
                isReviewMode: true,
                userAnswers: userAnswers,
                correctStatus: correctStatus,
                aiFeedbacks: _aiData?['questionFeedbacks'],
                overallFeedback: _aiData?['detailedAssessment'],
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
                flaggedQuestions:
                    (widget.resultData['flaggedQuestions'] as List?)
                        ?.cast<String>() ??
                    [],
                partNumber: widget.part.partNumber,
                correctStatus: correctStatus,
                aiFeedbacks: _aiData?['questionFeedbacks'],
                overallFeedback: _aiData?['detailedAssessment'],
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

  Widget _buildActionButtons(String? classId) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.premiumShadow,
                ),
                child: ElevatedButton.icon(
                  onPressed: _handleReview,
                  icon: _isLoadingDetail
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.visibility_rounded),
                  label: FittedBox(
                    child: Text(
                      _isLoadingDetail ? 'ĐANG TẢI...' : 'XEM LỜI GIẢI',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
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
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: OutlinedButton.icon(
                  onPressed: _showRetryConfirmation,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const FittedBox(
                    child: Text(
                      'LÀM LẠI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (classId != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassFeedbackScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              label: const Text(
                'Ý KIẾN GIÁO VIÊN',
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
        const SizedBox(height: 24),
        TextButton(
          onPressed: _onBack,
          child: const Text(
            'Quay lại danh sách bài tập',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
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

  Widget _buildTopicStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Điểm mạnh theo chủ đề'),
        const SizedBox(height: 16),
        ..._topicStats.entries.map((entry) {
          final String topic = entry.key == 'Tổng quát'
              ? 'Kỹ năng tổng hợp'
              : entry.key;
          final int correct = entry.value['correct']!;
          final int total = entry.value['total']!;
          final double percent = total > 0 ? correct / total : 0;

          final Color themeColor = percent >= 0.7
              ? AppColors.success
              : (percent >= 0.4 ? Colors.orange : AppColors.error);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 0,
              child: InkWell(
                onTap: () => _handleReview(filterTopic: entry.key),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getTopicIcon(entry.key),
                                  size: 18,
                                  color: themeColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                topic,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$correct/$total',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            percent >= 0.7
                                ? 'Hoàn thành tốt'
                                : (percent >= 0.4
                                      ? 'Cần cố gắng'
                                      : 'Cần xem lại ngay'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: themeColor,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  IconData _getTopicIcon(String topic) {
    String t = topic.toLowerCase();
    if (t.contains('ngữ pháp') || t.contains('grammar')) {
      return Icons.architecture;
    }
    if (t.contains('từ vựng') || t.contains('vocab')) return Icons.translate;
    if (t.contains('suy luận')) return Icons.psychology;
    if (t.contains('ý chính')) return Icons.summarize;
    return Icons.lightbulb_outline;
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
                title: Text(
                  q.topicTag ?? 'Câu hỏi ${q.questionNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Bạn chọn: $userAnswer - Đáp án: ${q.correctAnswer}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

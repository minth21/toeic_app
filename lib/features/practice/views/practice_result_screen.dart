import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../viewmodels/practice_viewmodel.dart';
import '../models/part_model.dart';
import 'reading_review_screen.dart';
import 'part1_simulation_screen.dart';

class PracticeResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;
  final PartModel part;
  final String attemptId;

  const PracticeResultScreen({
    super.key,
    required this.resultData,
    required this.part,
    required this.attemptId,
  });

  @override
  State<PracticeResultScreen> createState() => _PracticeResultScreenState();
}

class _PracticeResultScreenState extends State<PracticeResultScreen> {
  bool _isAnalyzing = true;
  Map<String, dynamic>? _aiData;
  final ScrollController _aiScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAIData();
  }

  Future<void> _fetchAIData() async {
    final viewModel = context.read<PracticeViewModel>();
    final data = await viewModel.pollAIAssessment(widget.attemptId);

    if (mounted) {
      setState(() {
        if (data != null) {
          try {
            _aiData = jsonDecode(data) as Map<String, dynamic>;
          } catch (e) {
            debugPrint('Error parsing AI data: $e');
          }
        }
        _isAnalyzing = false;
      });
    }
  }

  @override
  void dispose() {
    _aiScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int score = widget.resultData['score'] ?? 0;
    final int total = widget.resultData['totalQuestions'] ?? widget.resultData['total'] ?? 0;
    final double percentage = total > 0 ? (score / total) * 100 : 0;
    final bool isListening = widget.part.partNumber <= 4;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
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
                const SizedBox(height: 20),
                _buildScoreHeader(score, total, percentage),
                const SizedBox(height: 30),
                if (_isAnalyzing)
                  _buildAnalyzingState()
                else
                  _buildAnalysisContent(isListening),
                const SizedBox(height: 30),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeader(int score, int total, double percentage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.premiumShadow,
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.background,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                   Text(
                    'Score',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pastelBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tổng số câu đúng',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$score/$total',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.part.partName,
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Column(
      children: [
        Lottie.network(
          'https://assets10.lottiefiles.com/packages/lf20_m6cuL6.json',
          height: 200,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.psychology, size: 100, color: Colors.blue),
        ),
        const SizedBox(height: 20),
        const Text(
          'AI đang phân tích bài làm của bạn...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
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
          const SizedBox(height: 16),
          Container(
            height: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.softShadow,
            ),
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withValues(alpha: 0.3),
                    borderColor: AppColors.primary,
                    entryRadius: 4,
                    dataEntries: [
                      RadarEntry(value: (skills['grammar'] ?? 0).toDouble()),
                      RadarEntry(value: (skills['vocabulary'] ?? 0).toDouble()),
                      RadarEntry(value: (skills['inference'] ?? 0).toDouble()),
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
          const SizedBox(height: 32),
        ],
        if (_aiData?['strengths'] != null ||
            _aiData?['weaknesses'] != null) ...[
          _buildStrengthsWeaknesses(
            _aiData?['strengths'],
            _aiData?['weaknesses'],
          ),
          const SizedBox(height: 32),
        ],
        _buildSectionTitle('Gia sư AI nhận xét'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.softShadow,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Scrollbar(
              controller: _aiScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 4,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                controller: _aiScrollController,
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_aiData?['shortFeedback'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _aiData!['shortFeedback']
                              .toString()
                              .replaceAll('\\n', '\n')
                              .replaceAll('\\"', '"')
                              .replaceAll('\\t', '\t'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    HtmlWidget(
                      (_aiData?['detailedAssessment'] ??
                              '<p>Đang chuẩn bị nội dung đánh giá chi tiết...</p>')
                          .toString()
                          .replaceAll('\\n', '\n')
                          .replaceAll('\\"', '"')
                          .replaceAll('\\t', '\t'),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.premiumShadow,
          ),
          child: ElevatedButton(
            onPressed: () {
              if (widget.part.partNumber == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Part1SimulationScreen(
                      test: context.read<PracticeViewModel>().currentTest!,
                      partId: widget.part.id,
                      isReviewMode: true,
                      initialUserAnswers: (widget.resultData['userAnswers'] as Map).map<String, String>(
                        (k, v) => MapEntry(k.toString(), v.toString()),
                      ),
                      aiFeedbacks: _aiData?['questionFeedbacks'],
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                                    builder: (context) => ReadingReviewScreen(
                                      questions: context
                                          .read<PracticeViewModel>()
                                          .currentQuestions,
                                      userAnswers: (widget.resultData['userAnswers'] as Map).map<String, String>(
                                        (k, v) => MapEntry(k.toString(), v.toString()),
                                      ),
                                      partNumber: widget.part.partNumber,
                                      aiFeedbacks: _aiData?['questionFeedbacks'],
                                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded),
                SizedBox(width: 12),
                Text(
                  'SMART DEEP REVIEW',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
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
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../viewmodels/progress_viewmodel.dart';

class PartRecordDetailScreen extends StatefulWidget {
  final String partId;
  final String partName;
  final int partNumber;

  const PartRecordDetailScreen({
    super.key,
    required this.partId,
    required this.partName,
    required this.partNumber,
  });

  @override
  State<PartRecordDetailScreen> createState() => _PartRecordDetailScreenState();
}

class _PartRecordDetailScreenState extends State<PartRecordDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressViewModel>().loadPartHistory(widget.partId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.partName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.premiumGradient,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<ProgressViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.partHistory.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadPartHistory(widget.partId),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnalysisCard(viewModel.partHistory),
                  const SizedBox(height: 24),
                  _buildTrendChart(viewModel.partHistory),
                  const SizedBox(height: 32),
                  Text(
                    'LỊCH SỬ CHI TIẾT',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryList(viewModel.partHistory),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalysisCard(List<dynamic> history) {
    if (history.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.softShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Làm thêm bài tập để AI có thể phân tích tiến trình của bạn.',
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    // Simple improvement logic
    final latest = (history.first['correctCount'] as num).toDouble();
    final previous = (history[1]['correctCount'] as num).toDouble();
    final isImproving = latest >= previous;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isImproving ? AppColors.successGradient : AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isImproving ? Colors.green : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isImproving ? Icons.trending_up : Icons.trending_flat,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isImproving ? 'BẠN ĐANG TIẾN BỘ!' : 'GIỮ VỮNG PHONG ĐỘ',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isImproving 
                        ? 'Kết quả lần này tốt hơn so với lần trước. Tiếp tục phát huy nhé!'
                        : 'Điểm số chưa có sự đột phá. Hãy thử ôn lại các câu sai để cải thiện.',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
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

  Widget _buildTrendChart(List<dynamic> history) {
    // Reverse to show Chronological order in chart (Old -> New)
    final chartData = history.reversed.toList();
    final List<FlSpot> spots = [];
    
    double maxScore = 10; // Fallback
    for (int i = 0; i < chartData.length; i++) {
       final correct = (chartData[i]['correctCount'] as num).toDouble();
       final total = (chartData[i]['totalQuestions'] as num).toDouble();
       if (total > maxScore) maxScore = total;
       spots.add(FlSpot(i.toDouble(), correct));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.softShadow,
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == maxScore || value == (maxScore/2).roundToDouble()) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Lần ${value.toInt() + 1}',
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxScore + 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<dynamic> history) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final DateTime date = DateTime.parse(item['createdAt']);
        final score = item['correctCount'] ?? 0;
        final total = item['totalQuestions'] ?? 0;
        final percentage = total > 0 ? (score / total * 100).toInt() : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.softShadow,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildScoreCircle(percentage),
            title: Text(
              'Lần làm thứ ${history.length - index}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              DateFormat('HH:mm - dd/MM/yyyy').format(date),
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score/$total',
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Câu đúng',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCircle(int percentage) {
    Color color = AppColors.warning;
    if (percentage >= 80) {
      color = AppColors.success;
    } else if (percentage >= 50) {
      color = AppColors.primary;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$percentage%',
          style: GoogleFonts.outfit(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa làm bài nào ở Part này.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

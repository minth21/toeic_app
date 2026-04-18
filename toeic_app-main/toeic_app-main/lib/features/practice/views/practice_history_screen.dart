import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../viewmodels/practice_viewmodel.dart';
import 'practice_result_screen.dart';
import '../models/part_model.dart';

class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({super.key});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PracticeViewModel>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lịch sử luyện tập',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PracticeViewModel>().loadHistory(),
          ),
        ],
      ),
      body: Consumer<PracticeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử luyện tập',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy bắt đầu luyện tập để thấy quá trình tiến bộ nhé!',
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.loadHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.history.length,
              itemBuilder: (context, index) {
                final attempt = viewModel.history[index];
                return _buildHistoryItem(attempt);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> attempt) {
    final DateTime createdAt = DateTime.parse(attempt['createdAt']).toLocal();
    final String dateStr = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
    final String partName = attempt['part']?['partName'] ?? 'Part Unknown';
    final String testTitle = attempt['test']?['title'] ?? 'Bài luyện tập lẻ';
    final int correct = attempt['correctCount'] ?? 0;
    final int total = attempt['totalQuestions'] ?? 0;
    final int partNumber = attempt['part']?['partNumber'] ?? 5;
    final bool isListening = [1, 2, 3, 4].contains(partNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.softShadow,
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToResult(attempt),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: (isListening ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isListening ? Icons.headphones_rounded : Icons.menu_book_rounded,
                    color: isListening ? Colors.blue : Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        testTitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$correct/$total',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Đúng',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToResult(Map<String, dynamic> attempt) {
    // Map backend data to local models if necessary
    final partModel = PartModel.fromJson(attempt['part']);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeResultScreen(
          resultData: {
            'score': attempt['correctCount'] ?? 0,
            'total': attempt['totalQuestions'] ?? 0,
            'toeicScore': attempt['toeicScore'] ?? 0,
            'percentage': ((attempt['correctCount'] ?? 0) / (attempt['totalQuestions'] ?? 1)) * 100,
          },
          attemptId: attempt['id'],
          part: partModel,
        ),
      ),
    );
  }
}

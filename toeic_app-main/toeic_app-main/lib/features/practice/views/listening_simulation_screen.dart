import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../models/part_model.dart';
import '../models/question_model.dart';
import '../viewmodels/practice_viewmodel.dart';
import '../../../constants/app_constants.dart';
import 'widgets/custom_audio_player.dart';
import '../models/exam_model.dart';
import 'practice_result_screen.dart';
import 'widgets/vocab_flashcard_panel.dart';

class ListeningSimulationScreen extends StatefulWidget {
  final ExamModel test;
  final String? partId;
  final bool isReviewMode;
  final Map<String, String>? initialUserAnswers;
  final PartModel? part;
  final List<dynamic>? aiFeedbacks;
  final String? overallFeedback;
  final Set<String>? correctQuestionIds;
  final Set<int>? correctQuestionNumbers;

  const ListeningSimulationScreen({
    super.key,
    required this.test,
    this.partId,
    this.isReviewMode = false,
    this.initialUserAnswers,
    this.part,
    this.aiFeedbacks,
    this.overallFeedback,
    this.correctQuestionIds,
    this.correctQuestionNumbers,
  });

  @override
  State<ListeningSimulationScreen> createState() => _ListeningSimulationScreenState();
}

class _ListeningSimulationScreenState extends State<ListeningSimulationScreen> {
  final Map<String, String> _userAnswers = {};
  final Set<String> _flaggedQuestions = {};
  bool _isSubmitted = false;
  bool _showInstruction = true;
  PartModel? _selectedPart;
  final Set<int> _showTranslationGroups = {}; 
  
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isTimed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isReviewMode) {
      _isSubmitted = true;
      _showInstruction = false;
      if (widget.initialUserAnswers != null) {
        _userAnswers.addAll(widget.initialUserAnswers!);
      }
    }

    if (widget.partId != null) {
      try {
        _selectedPart = widget.test.parts.firstWhere((p) => p.id == widget.partId);
      } catch (e) {
        debugPrint("Part not found in test model: $e");
      }
    }
    
    _initializeTimer();
  }

  void _initializeTimer() {
    final partToUse = widget.part ?? _selectedPart;
    if (partToUse?.timeLimit != null && partToUse!.timeLimit! > 0) {
      setState(() {
        _remainingTime = Duration(seconds: partToUse.timeLimit!);
        _isTimed = true;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
        _submitTest();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hết giờ làm bài!')));
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _toggleFlag(String qId) {
    setState(() {
      if (_flaggedQuestions.contains(qId)) {
        _flaggedQuestions.remove(qId);
      } else {
        _flaggedQuestions.add(qId);
      }
    });
  }

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
                  child: const Text('Tiếp tục', textAlign: TextAlign.center),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Thoát', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getGroupIndexForQuestion(int questionIndex, List<List<QuestionModel>> groups) {
    int count = 0;
    for (int i = 0; i < groups.length; i++) {
      count += groups[i].length;
      if (questionIndex < count) return i;
    }
    return 0;
  }

  void _showQuestionPalette(List<QuestionModel> questions) {
    final groups = _groupQuestions(questions);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            Text('Bảng câu hỏi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final qId = questions[index].id.trim();
                  final targetGroupIdx = _getGroupIndexForQuestion(index, groups);
                  final bool isActive = targetGroupIdx == _currentIndex;
                  final String? userAnswer = _userAnswers[qId];
                  final bool isAnswered = userAnswer != null && userAnswer.trim().isNotEmpty;
                  final isFlagged = _flaggedQuestions.contains(qId);

                  Color bg = Colors.white;
                  Color border = isActive ? AppColors.primary : AppColors.divider;
                  Color text = AppColors.textSecondary;

                  if (widget.isReviewMode) {
                    String clean(String? s) {
                      if (s == null || s.isEmpty) return '';
                      final match = RegExp(r'[A-D]').firstMatch(s.trim().toUpperCase());
                      return match?.group(0) ?? s.trim().toUpperCase();
                    }

                    bool isCorrect = false;
                    final String cleanUser = clean(userAnswer);
                    final String cleanCorrect = clean(questions[index].correctAnswer);

                    if (widget.correctQuestionIds != null || widget.correctQuestionNumbers != null) {
                      final inIdSet = widget.correctQuestionIds?.contains(qId) ?? false;
                      final qNum = questions[index].questionNumber;
                      final inNumSet = widget.correctQuestionNumbers?.contains(qNum) ?? false;
                      isCorrect = inIdSet || inNumSet || (isAnswered && cleanUser == cleanCorrect);
                    } else {
                      isCorrect = isAnswered && cleanUser == cleanCorrect;
                    }

                    if (isCorrect) {
                      bg = const Color(0xFF10B981);
                      border = const Color(0xFF059669);
                      text = Colors.white;
                    } else if (isAnswered) {
                      bg = const Color(0xFFEF4444);
                      border = const Color(0xFFDC2626);
                      text = Colors.white;
                    } else {
                      bg = const Color(0xFFEF4444).withValues(alpha: 0.1);
                      border = const Color(0xFFEF4444).withValues(alpha: 0.3);
                      text = const Color(0xFFEF4444);
                    }
                  } else {
                    if (isAnswered) {
                      bg = AppColors.primary;
                      text = Colors.white;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pageController.jumpToPage(targetGroupIdx);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border, width: isActive ? 2.5 : 1.5),
                        boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${questions[index].questionNumber}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: text),
                          ),
                          if (isFlagged)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Icon(
                                Icons.flag_rounded,
                                size: 8,
                                color: (bg != Colors.white) ? Colors.white : Colors.amber,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onOptionSelected(String questionId, String option) {
    if (_isSubmitted) return;
    setState(() {
      _userAnswers[questionId] = option;
    });
  }

  Future<void> _submitTest() async {
    final viewModel = Provider.of<PracticeViewModel>(context, listen: false);

    setState(() {
      _isSubmitted = true;
    });

    final results = await viewModel.submitPart(
      widget.partId!,
      _userAnswers,
    );

    if (mounted && results != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PracticeResultScreen(
            resultData: results,
            part: _selectedPart!,
            attemptId: results['id']?.toString() ?? '',
            fromSimulation: true,
          ),
        ),
      );
    }
  }

  List<List<QuestionModel>> _groupQuestions(List<QuestionModel> questions) {
    if (questions.isEmpty) return [];

    final partNum = widget.part?.partNumber ?? _selectedPart?.partNumber ?? 0;
    
    if (partNum == 2) {
      return questions.map((q) => [q]).toList();
    }

    List<List<QuestionModel>> groups = [];
    if (questions.isEmpty) return groups;

    List<QuestionModel> currentGroup = [questions[0]];

    for (int i = 1; i < questions.length; i++) {
      final q = questions[i];
      final prev = questions[i - 1];

      bool isSameAudio = q.audioUrl != null && q.audioUrl!.isNotEmpty && q.audioUrl == prev.audioUrl;
      bool isSameImage = q.passageImageUrl != null && q.passageImageUrl!.isNotEmpty && q.passageImageUrl == prev.passageImageUrl;

      if (isSameAudio || isSameImage) {
        currentGroup.add(q);
      } else {
        groups.add(currentGroup);
        currentGroup = [q];
      }
    }
    groups.add(currentGroup);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isReviewMode || _isSubmitted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmDialog();
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _showInstruction && !widget.isReviewMode
          ? _buildInstructionScreen(context)
          : Consumer<PracticeViewModel>(
              builder: (context, viewModel, child) {
                final questions = viewModel.currentQuestions;
                final groups = _groupQuestions(questions);
                
                return Scaffold(
                  backgroundColor: AppColors.background,
                  appBar: AppBar(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () async {
                        if (widget.isReviewMode || _isSubmitted) {
                          Navigator.of(context).pop();
                        } else {
                          final shouldPop = await _showExitConfirmDialog();
                          if (shouldPop == true && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                    title: Text(
                      widget.isReviewMode ? 'Review Mode - Part ${widget.part?.partNumber ?? ""}' : 'Part ${widget.part?.partNumber ?? ""} Simulation',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    centerTitle: true,
                    actions: [
                      if (questions.isNotEmpty)
                        Row(
                          children: [
                            if (!widget.isReviewMode && !_isSubmitted)
                              IconButton(
                                icon: Icon(
                                  _flaggedQuestions.contains(questions.isNotEmpty ? questions[0].id : '') ? Icons.flag_rounded : Icons.flag_outlined,
                                  color: _flaggedQuestions.contains(questions.isNotEmpty ? questions[0].id : '') ? Colors.amber : Colors.white70,
                                ),
                                onPressed: () {
                                   if (groups.isNotEmpty && _currentIndex < groups.length) {
                                      _toggleFlag(groups[_currentIndex][0].id);
                                   }
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.grid_view_rounded),
                              onPressed: () => _showQuestionPalette(questions),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                    ],
                  ),
                  body: Builder(
                    builder: (context) {
                      if (viewModel.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (viewModel.error != null) {
                        return Center(child: Text('Error: ${viewModel.error}'));
                      }
                      if (questions.isEmpty) {
                        return const Center(child: Text('No questions available.'));
                      }

                  final currentGroup = groups[_currentIndex < groups.length ? _currentIndex : 0];
                  
                  String? rawAudioUrl;
                  for (var q in currentGroup) {
                    if (q.audioUrl != null && q.audioUrl!.isNotEmpty) {
                      rawAudioUrl = q.audioUrl;
                      break;
                    }
                  }
                  rawAudioUrl ??= _selectedPart?.audioUrl;
                  
                  final audioUrl = rawAudioUrl ?? '';
                  
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            if (audioUrl.isNotEmpty)
                              CustomAudioPlayer(
                                audioUrl: audioUrl,
                                subtitle: _selectedPart?.partName ?? 'Listening Practice',
                                autoPlay: !widget.isReviewMode,
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Group ${_currentIndex + 1}/${groups.length}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                if (_isTimed && !widget.isReviewMode && !_isSubmitted)
                                  Text(
                                    _formatDuration(_remainingTime),
                                    style: TextStyle(
                                      color: _remainingTime.inMinutes < 5 ? Colors.orange : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: groups.length,
                          onPageChanged: (idx) => setState(() => _currentIndex = idx),
                          itemBuilder: (context, groupIdx) {
                            final group = groups[groupIdx];
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: _buildConversationGroup(groupIdx, group),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              bottomNavigationBar: widget.isReviewMode ? _buildReviewPalette(questions) : _buildBottomNavigation(groups.length),
                );
              },
            ),
    );
  }

  Widget _buildInstructionScreen(BuildContext context) {
    const Color adminBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _selectedPart?.partName ?? 'Listening Practice',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: adminBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: adminBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.headphones_outlined, color: adminBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Directions",
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (widget.part?.instructionImgUrl != null && widget.part!.instructionImgUrl!.trim().isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          AppConstants.getFullUrl(widget.part!.instructionImgUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey)),
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: HtmlWidget(
                      _selectedPart?.instructions ?? "Hãy nghe kỹ đoạn hội thoại hoặc bài nói và trả lời các câu hỏi trắc nghiệm.",
                      textStyle: GoogleFonts.inter(fontSize: 15, height: 1.7, color: const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => setState(() => _showInstruction = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  "Bắt đầu làm bài",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(int totalGroups) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      color: AppColors.background,
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('TRƯỚC ĐÓ'),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentIndex == totalGroups - 1 ? _submitTest : () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: Text(_currentIndex == totalGroups - 1 ? 'NỘP BÀI NGAY' : 'TIẾP THEO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationGroup(int index, List<QuestionModel> questions) {
    final firstQuestion = questions.first;
    final List<String> graphicUrls = (firstQuestion.passageImageUrls)
        .where((url) => url.isNotEmpty)
        .toList();
    final String? transcript = firstQuestion.transcript;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.indigo50.withValues(alpha: 0.5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  questions.length > 1 
                    ? 'Questions ${questions.first.questionNumber}-${questions.last.questionNumber}'
                    : 'Question ${questions.first.questionNumber}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ),

          if (graphicUrls.isNotEmpty && (_selectedPart?.partNumber ?? 0) != 2)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: graphicUrls.map((url) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: Image.network(
                        AppConstants.getFullUrl(url),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),

          if (widget.isReviewMode && transcript != null && transcript.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TRANSCRIPT & TRANSLATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Colors.orange, letterSpacing: 1.2)),
                          Row(
                            children: [
                              _buildToggleOption(index, 'ENG', !_showTranslationGroups.contains(index)),
                              _buildToggleOption(index, 'VIE', _showTranslationGroups.contains(index)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           if (!_showTranslationGroups.contains(index))
                            HtmlWidget(
                              _beautifyTranscript(transcript),
                              textStyle: GoogleFonts.inter(fontSize: 15, height: 1.8, color: const Color(0xFF1E293B)),
                              customStylesBuilder: (element) {
                                if (element.classes.contains('speaker-label')) {
                                  return {
                                    'color': '#2563EB',
                                    'font-weight': '800',
                                    'background': '#EFF6FF',
                                    'padding': '2px 8px',
                                    'border-radius': '6px',
                                    'margin-right': '4px',
                                    'font-size': '12px',
                                    'display': 'inline-block',
                                    'border': '1px solid #DBEAFE',
                                  };
                                }
                                if (element.classes.contains('q-inline-badge')) {
                                  return {
                                    'color': '#FFFFFF',
                                    'font-weight': 'bold',
                                    'background': '#4F46E5',
                                    'padding': '1px 6px',
                                    'border-radius': '4px',
                                    'font-size': '11px',
                                    'margin': '0 4px',
                                  };
                                }
                                return null;
                              },
                            )
                          else
                            _buildTranslationContent(firstQuestion.passageTranslationData),
                          
                          _buildGeneralVocabulary(firstQuestion.passageTranslationData, firstQuestion.partId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: questions.map((q) => _buildQuestionItem(q)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _beautifyTranscript(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    
    final speakerRegex = RegExp(r'(^|<br\s*/?>|\n)([A-Z]{1,2}[\-\s][A-Z][a-z]{0,2}|Speaker\s[A-Z]|Man|Woman)([:\s])', multiLine: true);
    
    String processed = raw.replaceAllMapped(speakerRegex, (match) {
      final prefix = match.group(1) ?? "";
      final speaker = match.group(2) ?? "";
      final suffix = match.group(3) ?? "";
      return '$prefix<span class="speaker-label">$speaker$suffix</span>';
    });

    final qNumRegex = RegExp(r'\((\d+)\)');
    processed = processed.replaceAllMapped(qNumRegex, (match) {
      final num = match.group(1) ?? "";
      return '<span class="q-inline-badge">Q$num</span>';
    });

    return processed;
  }

  Widget _buildToggleOption(int groupIndex, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'VIE') {
            _showTranslationGroups.add(groupIndex);
          } else {
            _showTranslationGroups.remove(groupIndex);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.orange.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationContent(String? jsonData) {
    if (jsonData == null) return const SizedBox.shrink();
    try {
      final List<dynamic> data = jsonDecode(jsonData);
      if (data.isEmpty) return const Text('No translation available.');
      
      final block = data[0];
      if (block['type'] == 'general') {
        return Text(
          block['content'] ?? '',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.brown[800], fontStyle: FontStyle.italic, height: 1.5),
        );
      }
      
      final List<dynamic> items = block['items'] ?? [];
      final fullText = items.map((it) => it['vi']).join('\n\n');
      return Text(fullText, style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic, height: 1.5));
    } catch (e) {
      return const Text('Error decoding translation');
    }
  }

  Widget _buildGeneralVocabulary(String? jsonData, String? partId) {
    if (jsonData == null) return const SizedBox.shrink();
    try {
      final List<dynamic> data = jsonDecode(jsonData);
      if (data.isEmpty) return const SizedBox.shrink();
      
      final block = data[0];
      List<dynamic> vocabulary = [];

      if (block['type'] == 'general') {
        vocabulary = block['vocabulary'] ?? [];
      } else {
        final items = block['items'] ?? [];
        for (var it in items) {
          vocabulary.addAll(it['vocab'] ?? []);
        }
      }

      if (vocabulary.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: VocabFlashcardPanel(
          vocabItems: vocabulary,
          partId: partId ?? '',
          onAllSwiped: () {}, 
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildQuestionItem(QuestionModel question) {
    final partNum = widget.part?.partNumber ?? _selectedPart?.partNumber ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${question.questionNumber}. ${question.questionText ?? "Listen and choose the best answer."}',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildOption(question, 'A', question.optionA ?? ''),
          _buildOption(question, 'B', question.optionB ?? ''),
          _buildOption(question, 'C', question.optionC ?? ''),
          if (partNum != 2) _buildOption(question, 'D', question.optionD ?? ''),
          
          if (_isSubmitted && widget.isReviewMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Correct Answer: ${question.correctAnswer}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(QuestionModel question, String label, String text) {
    final bool isSelected = _userAnswers[question.id] == label;
    final bool isCorrect = _isSubmitted && question.correctAnswer == label;
    final bool isWrong = _isSubmitted && isSelected && question.correctAnswer != label;

    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.white;
    Color textColor = AppColors.textPrimary;

    if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.05);
    }

    if (_isSubmitted) {
      if (isCorrect) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
      } else if (isWrong) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
      }
    }

    return GestureDetector(
      onTap: () => _onOptionSelected(question.id, label),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected || (isCorrect || isWrong) ? borderColor : Colors.grey.shade400, width: 1.5),
                color: isSelected || (isCorrect || isWrong) ? borderColor : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected || (isCorrect || isWrong) ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: textColor),
              ),
            ),
            if (_isSubmitted)
              if (isCorrect)
                const Icon(Icons.check_circle, color: AppColors.success, size: 20)
              else if (isWrong)
                const Icon(Icons.cancel, color: AppColors.error, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewPalette(List<QuestionModel> questions) {
    final groups = _groupQuestions(questions);
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
                final qId = questions[i].id.trim();
                final targetGroupIdx = _getGroupIndexForQuestion(i, groups);
                final bool isActive = targetGroupIdx == _currentIndex;
                final String? userAnswer = _userAnswers[qId];
                final bool isAnswered = userAnswer != null && userAnswer.trim().isNotEmpty;
                
                Color bg = Colors.white;
                Color border = isActive ? AppColors.primary : AppColors.divider;
                Color text = AppColors.textSecondary;

                String clean(String? s) {
                  if (s == null || s.isEmpty) return '';
                  final match = RegExp(r'[A-D]').firstMatch(s.trim().toUpperCase());
                  return match?.group(0) ?? s.trim().toUpperCase();
                }

                bool isCorrect = false;
                if (widget.correctQuestionIds != null || widget.correctQuestionNumbers != null) {
                  final inIdSet = widget.correctQuestionIds?.contains(qId) ?? false;
                  final qNum = questions[i].questionNumber;
                  final inNumSet = widget.correctQuestionNumbers?.contains(qNum) ?? false;
                  isCorrect = inIdSet || inNumSet || (isAnswered && clean(userAnswer) == clean(questions[i].correctAnswer));
                } else {
                  isCorrect = isAnswered && clean(userAnswer) == clean(questions[i].correctAnswer);
                }

                if (isCorrect) {
                  bg = const Color(0xFF10B981);
                  border = const Color(0xFF10B981).withValues(alpha: 0.8);
                  text = Colors.white;
                } else {
                  bg = const Color(0xFFEF4444);
                  border = const Color(0xFFEF4444).withValues(alpha: 0.8);
                  text = Colors.white;
                }

                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      targetGroupIdx,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 40,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: border,
                        width: isActive ? 2.5 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${questions[i].questionNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: text,
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
}

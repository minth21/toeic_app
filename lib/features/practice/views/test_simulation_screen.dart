import 'dart:async';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam_model.dart';
import '../models/part_model.dart';
import '../viewmodels/practice_viewmodel.dart';
import '../../../l10n/app_localizations.dart';

class TestSimulationScreen extends StatefulWidget {
  final ExamModel test;
  final String? partId;

  const TestSimulationScreen({super.key, required this.test, this.partId});

  @override
  State<TestSimulationScreen> createState() => _TestSimulationScreenState();
}

class _TestSimulationScreenState extends State<TestSimulationScreen> {
  bool _showInstruction = true;
  PartModel? _selectedPart;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // State for tracking answers
  final Map<int, String> _userAnswers = {};
  bool _isSubmitted = false;

  // Timer State
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isTimed = false;

  @override
  void initState() {
    super.initState();
    if (widget.partId != null) {
      try {
        _selectedPart = widget.test.parts.firstWhere(
          (p) => p.id == widget.partId,
        );
      } catch (e) {
        // Part not found
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PracticeViewModel>().loadQuestions(widget.partId!);
      });
    } else {
      _showInstruction = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isTimed && _selectedPart?.timeLimit != null) {
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    if (_selectedPart!.timeLimit != null && _selectedPart!.timeLimit! > 0) {
      setState(() {
        _remainingTime = Duration(seconds: _selectedPart!.timeLimit!);
        _isTimed = true;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
        _submitTest();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hết giờ làm bài!')));
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _onOptionSelected(int questionIndex, String option) {
    if (_isSubmitted) return; // Prevent changing answers after submission
    setState(() {
      _userAnswers[questionIndex] = option;
    });
  }

  void _submitTest() {
    _timer?.cancel();
    setState(() {
      _isSubmitted = true;
    });

    // Calculate score (optional, for immediate feedback)
    final questions = context.read<PracticeViewModel>().currentQuestions;
    int correctCount = 0;
    for (int i = 0; i < questions.length; i++) {
      if (_userAnswers[i] == questions[i].correctAnswer) {
        correctCount++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã nộp bài! Kết quả: $correctCount/${questions.length}'),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showInstruction &&
        _selectedPart != null &&
        (_selectedPart!.instructions != null ||
            _selectedPart!.instructionImgUrl != null)) {
      return _buildInstructionScreen(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  if (_isTimed) ...[
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_remainingTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _remainingTime.inMinutes < 5 ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Consumer<PracticeViewModel>(
                    builder: (context, viewModel, child) {
                      return Text(
                        '${_currentIndex + 1}/${viewModel.currentQuestions.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<PracticeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(child: Text('Error: ${viewModel.error}'));
          }

          final questions = viewModel.currentQuestions;

          if (questions.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)?.translate('no_questions') ??
                    'Không có câu hỏi nào.',
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${question.questionNumber}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (question.questionText != null)
                            HtmlWidget(
                              question.questionText!,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 24),
                          _buildOption(
                            context,
                            index,
                            'A',
                            question.optionA,
                            question.correctAnswer,
                          ),
                          _buildOption(
                            context,
                            index,
                            'B',
                            question.optionB,
                            question.correctAnswer,
                          ),
                          _buildOption(
                            context,
                            index,
                            'C',
                            question.optionC,
                            question.correctAnswer,
                          ),
                          _buildOption(
                            context,
                            index,
                            'D',
                            question.optionD,
                            question.correctAnswer,
                          ),

                          if (_isSubmitted && question.explanation != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Đáp án đúng: ${question.correctAnswer}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  HtmlWidget(
                                    // Ensure visual separation for newlines if not HTML
                                    question.explanation!.contains('<')
                                        ? question.explanation!
                                        : question.explanation!.replaceAll(
                                            '\n',
                                            '<br><br>',
                                          ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      height: 1.6, // Improve line spacing
                                      color: Colors.black87,
                                    ),
                                    customStylesBuilder: (element) {
                                      if (element.localName == 'p') {
                                        return {'margin-bottom': '12px'};
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildBottomNavigation(questions.length),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    int questionIndex,
    String optionLabel,
    String? optionText,
    String? correctAnswer,
  ) {
    if (optionText == null) return const SizedBox.shrink();

    bool isSelected = _userAnswers[questionIndex] == optionLabel;
    bool isCorrect = correctAnswer == optionLabel;

    Color borderColor = Colors.grey.shade300;
    Color backgroundColor = Colors.white;
    Color textColor = Colors.black;

    if (_isSubmitted) {
      if (isCorrect) {
        borderColor = Colors.green;
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
      } else if (isSelected) {
        borderColor = Colors.red;
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
      }
    } else {
      if (isSelected) {
        borderColor = Colors.blue;
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue;
      }
    }

    return GestureDetector(
      onTap: () => _onOptionSelected(questionIndex, optionLabel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isSelected || (_isSubmitted && isCorrect) ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSubmitted && isCorrect
                    ? Colors.green
                    : (_isSubmitted && isSelected && !isCorrect
                          ? Colors.red
                          : (isSelected ? Colors.blue : Colors.grey.shade100)),
              ),
              child: Text(
                optionLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected || (_isSubmitted && (isCorrect || isSelected))
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (_isSubmitted) ...[
              if (isCorrect)
                const Icon(Icons.check_circle, color: Colors.green),
              if (isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(int totalQuestions) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentIndex > 0 ? _previousPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black,
            ),
            child: const Text('Previous'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentIndex < totalQuestions - 1) {
                _nextPage();
              } else {
                if (!_isSubmitted) {
                  _submitTest();
                } else {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(
              _currentIndex < totalQuestions - 1
                  ? 'Next'
                  : (_isSubmitted ? 'Finish' : 'Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_selectedPart?.partName ?? 'Instructions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Directions:",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_selectedPart!.instructionImgUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Image.network(
                  _selectedPart!.instructionImgUrl!,
                ), // Ensure valid URL handling in production
              ),
            if (_selectedPart!.instructions != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _selectedPart!.instructions!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showInstruction = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  AppLocalizations.of(context)?.translate('start') ?? "Start",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

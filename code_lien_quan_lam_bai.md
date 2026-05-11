# Các đoạn mã nguồn liên quan đến luồng Làm bài ôn luyện

Dưới đây là các đoạn code thực tế trích xuất từ dự án minh chứng cho Sơ đồ hoạt động chức năng "Làm bài ôn luyện" (Practice/Test Simulation).

## 1. Kiểm tra lịch sử và Bắt đầu bài thi (Mobile App)
**Tệp:** `lib/features/practice/views/test_detail_screen.dart`

Hàm `_checkHistoryAndStart` kiểm tra xem người dùng đã từng làm Part này chưa thông qua API. Nếu đã làm, hiển thị điểm và tuỳ chọn xem lại. Nếu chưa, gọi `_directSimulation` để vào bài thi.

```dart
Future<void> _checkHistoryAndStart(PartModel part) async {
  setState(() => _isProcessing = true);
  final viewModel = Provider.of<PracticeViewModel>(context, listen: false);

  try {
    // Gọi API lấy lịch sử bài làm của Part này
    final history = await viewModel.getPartHistory(part.id);
    
    // ... Khởi tạo Dialog UI hiển thị Hướng dẫn hoặc Thành tích cũ
    
    final bool? ready = await showDialog<bool>(
      context: context,
      builder: (ctx) {
         // Hiển thị Dialog (LÀM LẠI / BẮT ĐẦU NGAY / XEM LẠI)
         // ...
      }
    );

    // Nếu người dùng ấn "Bắt đầu ngay" hoặc "Làm lại"
    if (ready == true) {
      await _directSimulation(part);
    }
  } catch (e) {
    debugPrint("Error in _checkHistoryAndStart: $e");
  }
}

Future<void> _directSimulation(PartModel part) async {
  _showLoadingDialog(context, message: 'Đang chuẩn bị bài thi...');
  
  final viewModel = Provider.of<PracticeViewModel>(context, listen: false);
  // Tải danh sách câu hỏi
  await viewModel.loadQuestions(part.id);

  Navigator.pop(context); // Tắt loading

  // Chuyển hướng sang màn hình Simulation tương ứng
  await Navigator.push(context, MaterialPageRoute(builder: (context) {
    if (part.partNumber == 1) return Part1SimulationScreen(test: _test, partId: part.id);
    if (part.partNumber == 3 || part.partNumber == 4) return ListeningSimulationScreen(test: _test, partId: part.id, part: part);
    return TestSimulationScreen(test: _test, partId: part.id);
  }));
}
```

## 2. Quá trình làm bài và Nộp bài (Mobile App)
**Tệp:** `lib/features/practice/views/test_simulation_screen.dart`

Quản lý `Timer` (tính giờ) và hàm `_submitTest()` để tổng hợp đáp án (`_userAnswers`), thời gian làm bài (`_timePerQuestion`) và gửi lên Backend.

```dart
// Bắt đầu bộ đếm giờ tổng thể và đếm giây từng câu
void _startTimer() {
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_remainingTime.inSeconds > 0) {
      setState(() => _remainingTime = _remainingTime - const Duration(seconds: 1));
    } else {
      _timer?.cancel();
      _submitTest(); // Tự động nộp khi hết giờ
    }
  });
}

// Lưu đáp án khi User chọn
void _onOptionSelected(String questionId, String option) {
  if (_isSubmitted || _isSubmitting) return;
  setState(() {
    _userAnswers[questionId] = option;
  });
}

// Xử lý nộp bài
Future<void> _submitTest() async {
  if (_isSubmitting) return;
  _timer?.cancel();
  setState(() => _isSubmitting = true);

  final viewModel = context.read<PracticeViewModel>();
  
  // Tính tổng thời gian đã dùng
  int totalTime = 0;
  for (var t in _timePerQuestion.values) totalTime += t;

  // Gọi API Submit Part
  final result = await viewModel.submitPart(
    widget.partId!,
    _userAnswers,
    timeTaken: totalTime,
  );

  if (result != null) {
    // Chuyển sang trang kết quả ngay lập tức
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeResultScreen(
          resultData: {
            ...result, 
            'userAnswers': _userAnswers,
            'flaggedQuestions': _flaggedQuestions.toList(),
          },
          part: _selectedPart!,
          attemptId: (result['attemptId'] ?? result['id']).toString(),
          fromSimulation: true,
        ),
      ),
    );
  }
}
```

## 3. Xử lý chấm điểm và Database Transaction (Backend)
**Tệp:** `src/controllers/practice.controller.ts`

Backend tiếp nhận API, so sánh đáp án, lưu lịch sử học tập qua Prisma Transaction và chạy Background Job cho AI Service.

```typescript
export const submitPart = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    let { userId, partId, answers, timeTaken } = req.body;

    // 1. Lấy thông tin Part và Đáp án đúng từ CSDL
    const questions = await prisma.question.findMany({ where: { partId } });

    // 2. Chấm điểm & Gom nhóm câu sai
    let correctCount = 0;
    const errorDetails: any[] = [];
    
    questions.forEach(q => {
        const selected = answerMap.get(q.id);
        const correct = q.correctAnswer;
        if (selected === correct && selected.length > 0) {
            correctCount++;
        } else {
            errorDetails.push({ questionText: q.questionText, selectedOption: selected, correctAnswer: correct });
        }
    });

    const toeicScore = calculateRawToeicScore(correctCount, skillType);

    // 3. Database Transaction: Lưu kết quả và cập nhật Streak/Tiến độ User
    const savedProgress = await prisma.$transaction(async (tx) => {
        const attempt = await tx.testAttempt.create({
            data: { userId, partId, durationSeconds: timeTaken, correctCount, totalScore: toeicScore /* ... */ }
        });
        
        await tx.attemptDetail.createMany({ data: detailData }); // Lưu từng câu

        // Update User Streak & Average Score
        await tx.user.update({
            where: { id: userId },
            data: { currentStreak: newStreak, totalAttempts: { increment: 1 }, /* ... */ }
        });

        return { attempt };
    });

    // 4. Trả kết quả ngay cho Mobile App để tránh Timeout UX
    res.status(200).json({ success: true, data: { attemptId: savedProgress.attempt.id, score: correctCount, /* ... */ }});

    // 5. BACKGROUND JOB: Đẩy cho Gemini AI phân tích
    (async () => {
        const finalAiResult = await evaluateProgress(correctCount, totalQuestions, /* ... */ JSON.stringify(errorDetails));
        
        // Cập nhật nhận xét AI vào TestAttempt
        await prisma.testAttempt.update({
            where: { id: savedProgress.attempt.id },
            data: { aiAnalysis: JSON.stringify(finalAiResult) }
        });
        
        // Tạo AiAssessment Timeline cho giáo viên/học viên
        await prisma.aiAssessment.create({ data: { testAttemptId: savedProgress.attempt.id, content: finalAiResult /* ... */ }});
    })();
};
```

## 4. Polling lấy kết quả phân tích AI (Mobile App)
**Tệp:** `lib/features/practice/views/practice_result_screen.dart` & `lib/features/practice/viewmodels/practice_viewmodel.dart`

App hiển thị điểm tức thì và thực hiện gọi API (Polling) liên tục để lấy đánh giá chuyên sâu từ hệ thống AI bất đồng bộ.

```dart
// Gọi API Polling trong PracticeViewModel
Future<String?> pollAIAssessment(String attemptId) async {
  const fastInterval = Duration(seconds: 3);
  const totalRetries = 50; // Thử tối đa ~150s

  for (int retries = 0; retries < totalRetries; retries++) {
    await Future.delayed(fastInterval);
    try {
      final attempt = await _apiService.getAttemptDetail(attemptId);
      final aiData = attempt?['aiAnalysis'] ?? attempt?['aiAssessment'];
      
      // Nếu đã có dữ liệu AI -> Trả về để UI cập nhật
      if (aiData != null && aiData.toString().isNotEmpty) {
        return aiData.toString();
      }
    } catch (e) {
      // Ignored: Tiếp tục retry
    }
  }
  return null;
}

// Cập nhật UI trong PracticeResultScreen
Future<void> _fetchAIData() async {
  setState(() => _isAnalyzing = true);
  final viewModel = context.read<PracticeViewModel>();
  
  // Gọi hàm polling, đợi cho đến khi Backend phân tích xong
  final data = await viewModel.pollAIAssessment(widget.attemptId);

  if (mounted) {
    setState(() {
      if (data != null) {
        _aiData = jsonDecode(data); // Render Flashcard, Radar Chart, Text Feedback
      }
      _isAnalyzing = false; // Tắt Skeleton Loading
    });
  }
}
```

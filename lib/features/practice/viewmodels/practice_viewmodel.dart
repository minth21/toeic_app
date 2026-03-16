import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../models/exam_model.dart';
import '../services/practice_api_service.dart';

class PracticeViewModel extends ChangeNotifier {
  final PracticeApiService _apiService = PracticeApiService();

  List<ExamModel> _tests = [];
  bool _isLoading = false;
  String? _selectedDifficulty;
  String? _error;
  ExamModel? _currentTest;

  List<ExamModel> get tests => _tests;
  bool get isLoading => _isLoading;
  String? get selectedDifficulty => _selectedDifficulty;
  String? get error => _error;
  ExamModel? get currentTest => _currentTest;

  PracticeViewModel() {
    loadTests();
  }

  Future<void> loadTests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tests = await _apiService.getTests(difficulty: _selectedDifficulty);
    } catch (e) {
      _error = e.toString();
      _tests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<QuestionModel> _currentQuestions = [];
  List<QuestionModel> get currentQuestions => _currentQuestions;

  Future<void> loadQuestions(String partId) async {
    _isLoading = true;
    _error = null;
    _currentQuestions = [];
    notifyListeners();

    try {
      _currentQuestions = await _apiService.getQuestionsByPartId(partId);
      // Find current test from loaded tests if available
      for (var test in _tests) {
        if (test.parts.any((p) => p.id == partId)) {
          _currentTest = test;
          break;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> submitPart(
    String partId,
    Map<String, String> userAnswers, {
    int? timeTaken,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> formattedAnswers = [];
      userAnswers.forEach((qId, answer) {
        formattedAnswers.add({
          'questionId': qId,
          'selectedOption': answer,
        });
      });

      final result = await _apiService.submitPart(
        partId,
        formattedAnswers,
        timeTaken,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getPartHistory(String partId) async {
    try {
      return await _apiService.getPartHistory(partId);
    } catch (e) {
      return [];
    }
  }

  void setDifficulty(String? difficulty) {
    if (_selectedDifficulty == difficulty) return;
    _selectedDifficulty = difficulty;
    loadTests();
  }

  Future<ExamModel?> getTestById(String testId) async {
    try {
      // Create a temporary/helper service call or use existing one if method exists
      // Check PracticeApiService for getTestById
      // If not exists, we might need to add it or just reload all tests and find it?
      // Reloading all is inefficient. Let's start with reloading all tests for simplicity
      // or assume we need to add a specific method.
      // Actually, the backend supports GET /api/tests/:id.
      // Let's check PracticeApiService again.
      return await _apiService.getTestById(testId);
    } catch (e) {
      return null;
    }
  }

  Future<String?> pollAIAssessment(String attemptId) async {
    int retries = 15; // 30 seconds max
    while (retries > 0) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final attempt = await _apiService.getAttemptDetail(attemptId);
        if (attempt != null && attempt['aiAssessment'] != null) {
          return attempt['aiAssessment'];
        }
      } catch (e) {
        // Ignore errors during polling
      }
      retries--;
    }
    return null;
  }
}

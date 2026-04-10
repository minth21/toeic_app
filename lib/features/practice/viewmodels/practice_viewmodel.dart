import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/question_model.dart';
import '../models/exam_model.dart';
import '../services/practice_api_service.dart';
import '../../../core/services/storage_service.dart';

class PracticeViewModel extends ChangeNotifier {
  final PracticeApiService _apiService = PracticeApiService();

  List<ExamModel> _tests = [];
  bool _isLoading = false;
  String? _selectedDifficulty;
  String? _selectedSkill; // 'listening', 'reading', or null (all)
  String? _error;
  ExamModel? _currentTest;

  List<ExamModel> get tests {
    if (_selectedSkill == null) return _tests;
    return _tests.where((test) {
      if (_selectedSkill == 'listening') return test.listeningQuestions > 0;
      if (_selectedSkill == 'reading') return test.readingQuestions > 0;
      return true;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get selectedDifficulty => _selectedDifficulty;
  String? get selectedSkill => _selectedSkill;
  String? get error => _error;
  ExamModel? get currentTest => _currentTest;

  PracticeViewModel() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    final storage = StorageService();
    _selectedDifficulty = await storage.getDifficulty();
    _selectedSkill = await storage.getSkill();
    loadTests();
    loadHistory();
  }

  Future<void> loadTests() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _tests = await _apiService.getTests(difficulty: _selectedDifficulty);
    } catch (e) {
      _error = e.toString();
      _tests = [];
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> get history => _history;

  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _history = await _apiService.getUserHistory();
    } catch (e) {
      _error = e.toString();
      _history = [];
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  List<QuestionModel> _currentQuestions = [];
  List<QuestionModel> get currentQuestions => _currentQuestions;

  Future<void> loadQuestions(String partId) async {
    _isLoading = true;
    _error = null;
    _currentQuestions = [];
    _safeNotifyListeners();

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
      _safeNotifyListeners();
    }
  }

  Future<Map<String, dynamic>?> submitPart(
    String partId,
    Map<String, String> userAnswers, {
    int? timeTaken,
  }) async {
    _isLoading = true;
    _safeNotifyListeners();

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
      _safeNotifyListeners();
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
    StorageService().saveDifficulty(difficulty);
    loadTests();
  }

  void setSkillFilter(String? skill) {
    if (_selectedSkill == skill) return;
    _selectedSkill = skill;
    StorageService().saveSkill(skill);
    notifyListeners();
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
    // Strategy: check immediately, then every 3s for first 60s,
    // then every 5s up to 150s total — covers slow AI / retry cases.
    const fastInterval = Duration(seconds: 3);
    const slowInterval = Duration(seconds: 5);
    const fastPhaseEnd = 20; // first 20 retries = 60s at 3s each
    const totalRetries = 50; // up to ~150s total

    for (int retries = 0; retries < totalRetries; retries++) {
      // On first iteration, do a small delay to let the background job start
      if (retries == 0) {
        await Future.delayed(const Duration(seconds: 4));
      } else {
        await Future.delayed(retries < fastPhaseEnd ? fastInterval : slowInterval);
      }

      try {
        final attempt = await _apiService.getAttemptDetail(attemptId);
        final aiData = attempt?['aiAnalysis'] ?? attempt?['aiAssessment'];
        if (aiData != null && aiData.toString().isNotEmpty) {
          debugPrint('[AI Poll] Got AI data after ${retries + 1} retries');
          return aiData.toString();
        }
      } catch (e) {
        // Ignore errors during polling, keep retrying
        debugPrint('[AI Poll] Error at retry $retries: $e');
      }
    }

    debugPrint('[AI Poll] Timeout after $totalRetries retries for attempt $attemptId');
    return null;
  }

  Future<bool> saveFlashcards(List<Map<String, dynamic>> flashcards, String partId) async {
    return await _apiService.saveFlashcards(flashcards, partId);
  }

  Future<List<Map<String, dynamic>>> getDailyRecommendations() async {
    return await _apiService.getDailyRecommendations();
  }

  Future<Map<String, dynamic>?> loadAttemptDetail(String attemptId) async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      return await _apiService.getAttemptDetail(attemptId);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}

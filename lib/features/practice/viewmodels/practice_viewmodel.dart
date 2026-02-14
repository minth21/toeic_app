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

  List<ExamModel> get tests => _tests;
  bool get isLoading => _isLoading;
  String? get selectedDifficulty => _selectedDifficulty;
  String? get error => _error;

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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> submitPart(
    String partId,
    Map<int, String> userAnswers,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> formattedAnswers = [];
      userAnswers.forEach((index, answer) {
        if (index < _currentQuestions.length) {
          formattedAnswers.add({
            'questionId': _currentQuestions[index].id,
            'selectedOption': answer,
          });
        }
      });

      final result = await _apiService.submitPart(partId, formattedAnswers);
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
}

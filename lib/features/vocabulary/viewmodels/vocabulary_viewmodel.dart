import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/vocabulary_service.dart';

class VocabularyViewModel extends ChangeNotifier {
  final VocabularyService _service = VocabularyService();

  List<Flashcard> _flashcards = [];
  bool _isLoading = false;
  String? _error;

  List<Flashcard> get flashcards => _flashcards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Check if a word is already in the flashcard collection
  bool isWordSaved(String word) {
    if (word.isEmpty) return false;
    final normalized = word.trim().toLowerCase();
    return _flashcards.any((f) => f.word.trim().toLowerCase() == normalized);
  }

  VocabularyViewModel() {
    loadFlashcards();
  }

  /// Tải danh sách flashcards
  Future<void> loadFlashcards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _flashcards = await _service.getFlashcards();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lưu flashcards mới từ bài làm
  Future<bool> saveNewVocab(List<Map<String, dynamic>> vocab, String? partId) async {
    final success = await _service.saveFlashcards(vocab, partId);
    if (success) {
      await loadFlashcards(); // Tải lại danh sách
    }
    return success;
  }

  /// Xóa flashcard
  Future<void> deleteFlashcard(String id) async {
    final success = await _service.deleteFlashcard(id);
    if (success) {
      _flashcards.removeWhere((f) => f.id == id);
      notifyListeners();
    }
  }
}

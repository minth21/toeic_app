import 'package:flutter/material.dart';
import '../models/ai_assessment.dart';
import '../services/ai_timeline_service.dart';

class AiTimelineViewModel extends ChangeNotifier {
  final AiTimelineService _service = AiTimelineService();

  List<AiAssessment> _assessments = [];
  Map<DateTime, List<AiAssessment>> _groupedAssessments = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<AiAssessment> get assessments => _assessments;
  Map<DateTime, List<AiAssessment>> get groupedAssessments => _groupedAssessments;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Tải dữ liệu Timeline lần đầu
  Future<void> loadTimeline(String userId) async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _assessments = [];
    _groupedAssessments = {};
    notifyListeners();

    try {
      final result = await _service.getTimeline(
        userId: userId,
        page: _currentPage,
      );

      if (result['success']) {
        _assessments = result['assessments'];
        _hasMore = _currentPage < (result['meta']['totalPages'] ?? 1);
        _groupAssessments();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải thêm dữ liệu (Pagination)
  Future<void> loadMore(String userId) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final result = await _service.getTimeline(
        userId: userId,
        page: _currentPage,
      );

      if (result['success']) {
        final newItems = result['assessments'] as List<AiAssessment>;
        _assessments.addAll(newItems);
        _hasMore = _currentPage < (result['meta']['totalPages'] ?? 1);
        _groupAssessments();
      }
    } catch (e) {
      _error = e.toString();
      _currentPage--; // Revert page on error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Gộp nhóm nhận xét theo ngày
  void _groupAssessments() {
    final Map<DateTime, List<AiAssessment>> groups = {};
    
    for (var item in _assessments) {
      // Chỉ lấy ngày (năm, tháng, ngày) để gộp nhóm
      final date = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      
      if (!groups.containsKey(date)) {
        groups[date] = [];
      }
      groups[date]!.add(item);
    }
    
    _groupedAssessments = groups;
  }
}

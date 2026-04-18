import 'package:flutter/material.dart';
import '../services/dashboard_api_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardApiService _apiService = DashboardApiService();

  Map<String, dynamic>? _dashboardData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Convenience getters
  String get userName => _dashboardData?['user']?['name'] ?? 'Bạn';
  int get progress => _dashboardData?['user']?['progress'] ?? 0;
  int get targetScore => _dashboardData?['user']?['targetScore'] ?? 0;
  int get predictedScore => _dashboardData?['user']?['estimatedScore'] ?? 0;
  int get listeningScore => _dashboardData?['user']?['estimatedListening'] ?? 0;
  int get readingScore => _dashboardData?['user']?['estimatedReading'] ?? 0;
  int get streak => _dashboardData?['streak'] ?? 0;
  List<dynamic> get recentActivities => _dashboardData?['recentActivities'] ?? [];
  List<dynamic> get learningTimeline => _dashboardData?['learningTimeline'] ?? [];
  List<dynamic> get recommendations => _dashboardData?['recommendations'] ?? [];
  Map<String, dynamic>? get resumeLearning => _dashboardData?['resumeLearning'];
  List<dynamic> get activityStats => _dashboardData?['activityStats'] ?? [];

  Map<DateTime, int> get heatmapData {
    final stats = activityStats;
    if (stats.isEmpty) return {};

    final result = <DateTime, int>{};

    for (var entry in stats) {
      final dateStr = entry['date'] as String?;
      final count = (entry['count'] as num?)?.toInt() ?? 0;
      
      if (dateStr != null && count > 0) {
        try {
          final date = DateTime.parse(dateStr);
          final cleanDate = DateTime(date.year, date.month, date.day);
          result[cleanDate] = count;
        } catch (e) {
          debugPrint('Error parsing dashboard date: $dateStr - $e');
        }
      }
    }
    return result;
  }

  Map<DateTime, String> get milestoneData {
    final milestones = _dashboardData?['milestones'] as List? ?? [];
    final result = <DateTime, String>{};

    for (var m in milestones) {
      final dateStr = m['date'] as String?;
      final label = m['label'] as String? ?? 'Cột mốc';
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          final cleanDate = DateTime(date.year, date.month, date.day);
          result[cleanDate] = label;
        } catch (e) {
          debugPrint('Error parsing milestone date: $dateStr - $e');
        }
      }
    }
    return result;
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardData = await _apiService.getStudentDashboard();
      debugPrint('--- RAW DASHBOARD DATA ---');
      debugPrint(_dashboardData.toString());
      debugPrint('Activity Stats Count: ${activityStats.length}');
      debugPrint('Heatmap Data: $heatmapData');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

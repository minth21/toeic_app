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
  int get targetScore => _dashboardData?['user']?['targetScore'] ?? 800;
  int get predictedScore => _dashboardData?['user']?['estimatedScore'] ?? 0;
  int get listeningScore => _dashboardData?['user']?['estimatedListening'] ?? 0;
  int get readingScore => _dashboardData?['user']?['estimatedReading'] ?? 0;
  int get streak => _dashboardData?['streak'] ?? 0;
  List<dynamic> get recentActivities => _dashboardData?['recentActivities'] ?? [];
  List<dynamic> get recommendations => _dashboardData?['recommendations'] ?? [];
  Map<String, dynamic>? get resumeLearning => _dashboardData?['resumeLearning'];
  List<dynamic> get activityStats => _dashboardData?['activityStats'] ?? [];

  /// Converts activityStats (last 7 days) → `Map<DateTime, int>` for heatmap.
  /// Reconstructs real DateTime by counting back from today.
  Map<DateTime, int> get heatmapData {
    final stats = activityStats;
    if (stats.isEmpty) return {};

    final result = <DateTime, int>{};
    final today = DateTime.now();

    // activityStats is ordered oldest → newest (index 0 = 6 days ago)
    for (int i = 0; i < stats.length; i++) {
      final count = (stats[i]['count'] as num?)?.toInt() ?? 0;
      if (count > 0) {
        final daysAgo = stats.length - 1 - i;
        final date = DateTime(
          today.year,
          today.month,
          today.day - daysAgo,
        );
        result[date] = count;
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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

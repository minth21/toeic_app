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

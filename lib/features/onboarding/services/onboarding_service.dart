import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding Service - Helper for local storage operations
class OnboardingService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keySelectedLevel = 'selected_toeic_level';

  /// Check if this is first time app launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// Mark that user has completed first launch flow
  static Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  /// Save selected TOEIC level (1-5)
  static Future<void> saveSelectedLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySelectedLevel, level);
  }

  /// Get saved TOEIC level
  static Future<int?> getSelectedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySelectedLevel);
  }

  /// Clear saved level (after sync to backend)
  static Future<void> clearSelectedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedLevel);
  }

  /// Reset all onboarding data (for testing)
  static Future<void> resetOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstLaunch);
    await prefs.remove(_keySelectedLevel);
  }
}

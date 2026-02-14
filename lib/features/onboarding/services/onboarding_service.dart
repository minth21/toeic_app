import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding Service - Helper for local storage operations
class OnboardingService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keySelectedDifficulty = 'selected_difficulty';

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

  /// Save selected Difficulty (EASY, MEDIUM, HARD)
  static Future<void> saveSelectedDifficulty(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedDifficulty, difficulty);
  }

  /// Get saved Difficulty
  static Future<String?> getSelectedDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedDifficulty);
  }

  /// Clear saved difficulty
  static Future<void> clearSelectedDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedDifficulty);
  }

  /// Reset all onboarding data (for testing)
  static Future<void> resetOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstLaunch);
    await prefs.remove(_keySelectedDifficulty);
  }
}

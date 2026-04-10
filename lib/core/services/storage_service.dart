import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _difficultyKey = 'pref_difficulty';
  static const String _skillKey = 'pref_skill';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  // --- Preferences ---

  Future<void> saveDifficulty(String? difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    if (difficulty == null) {
      await prefs.remove(_difficultyKey);
    } else {
      await prefs.setString(_difficultyKey, difficulty);
    }
  }

  Future<String?> getDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_difficultyKey);
  }

  Future<void> saveSkill(String? skill) async {
    final prefs = await SharedPreferences.getInstance();
    if (skill == null) {
      await prefs.remove(_skillKey);
    } else {
      await prefs.setString(_skillKey, skill);
    }
  }

  Future<String?> getSkill() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_skillKey);
  }
}

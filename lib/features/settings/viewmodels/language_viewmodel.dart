import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageViewModel extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  Locale _locale = const Locale('vi'); // Default to Vietnamese

  Locale get locale => _locale;

  bool get isVietnamese => _locale.languageCode == 'vi';

  LanguageViewModel() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> toggleLanguage(bool isVietnamese) async {
    _locale = isVietnamese ? const Locale('vi') : const Locale('en');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _locale.languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    if (!['vi', 'en'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _locale.languageCode);
  }
}

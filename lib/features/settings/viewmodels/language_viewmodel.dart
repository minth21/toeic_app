import 'package:flutter/material.dart';

class LanguageViewModel extends ChangeNotifier {
  Locale _locale = const Locale('vi'); // Locked to Vietnamese

  Locale get locale => _locale;

  bool get isVietnamese => true;
  bool get isEnglish => false;

  LanguageViewModel() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    // Force Vietnamese, ignore saved preferences
    _locale = const Locale('vi');
    notifyListeners();
  }

  Future<void> toggleLanguage(bool isEnglish) async {
    // Disabled: Does nothing to keep app in Vietnamese
  }

  Future<void> setLocale(Locale locale) async {
    // Disabled: Does nothing to keep app in Vietnamese
  }
}

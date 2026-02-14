import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  // Simple hardcoded map for now
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'logout': 'Logout',
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'change_password': 'Change Password',
      'personal_information': 'Personal Information',
      'account_settings': 'Account Settings',
      'confirm_logout': 'Confirm Logout',
      'logout_message': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      // Practice Screen
      'practice': 'Practice',
      'all': 'All',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'start_now': 'Start Now',
      'questions': 'questions',
      'minutes': 'min',
      'no_tests_found': 'No tests found',
      'error_occurred': 'An error occurred',
      'retry': 'Retry',
      // Test Detail & Simulation
      'difficulty': 'Difficulty',
      'duration': 'Duration',
      'total_questions': 'Total Questions',
      'structure': 'Structure',
      'listening': 'Listening',
      'reading': 'Reading',
      'start_test': 'Start Test',
      'test_simulation': 'Test Simulation',
      'coming_soon': 'Feature coming soon...',
    },
    'vi': {
      'settings': 'Cài đặt',
      'dark_mode': 'Chế độ tối',
      'language': 'Ngôn ngữ',
      'logout': 'Đăng xuất',
      'profile': 'Cá nhân',
      'edit_profile': 'Chỉnh sửa hồ sơ',
      'change_password': 'Đổi mật khẩu',
      'personal_information': 'Thông tin cá nhân',
      'account_settings': 'Cài đặt tài khoản',
      'confirm_logout': 'Xác nhận đăng xuất',
      'logout_message': 'Bạn có chắc chắn muốn đăng xuất?',
      'cancel': 'Hủy',
      'confirm': 'Đồng ý',
      // Practice Screen
      'practice': 'Luyện tập',
      'all': 'Tất cả',
      'easy': 'Dễ',
      'medium': 'Trung bình',
      'hard': 'Khó',
      'start_now': 'Làm bài ngay',
      'questions': 'câu',
      'minutes': 'phút',
      'no_tests_found': 'Không tìm thấy đề thi nào',
      'error_occurred': 'Có lỗi xảy ra',
      'retry': 'Thử lại',
      // Test Detail & Simulation
      'difficulty': 'Độ khó',
      'duration': 'Thời gian',
      'total_questions': 'Tổng số câu',
      'structure': 'Cấu trúc đề thi',
      'listening': 'Nghe hiểu',
      'reading': 'Đọc hiểu',
      'start_test': 'Bắt đầu làm bài',
      'test_simulation': 'Mô phỏng bài thi',
      'coming_soon': 'Chức năng đang phát triển...',
    },
  };

  Future<bool> load() async {
    _localizedStrings =
        _localizedValues[locale.languageCode] ?? _localizedValues['en']!;
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

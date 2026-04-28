import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (instance == null) {
      debugPrint('WARNING: AppLocalizations not found in context! Falling back to keys.');
    }
    return instance;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'logout': 'Logout',
      'profile': 'Profile',
      'profile_tab': 'Profile',
      'home': 'Home',
      'edit_profile': 'Edit Profile',
      'change_password': 'Change Password',
      'personal_information': 'Personal Information',
      'account_settings': 'Account Settings',
      'confirm_logout': 'Confirm Logout',
      'logout_message': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save_changes': 'Save Changes',
      'update_success': 'Update successful!',
      'update_failed': 'Update failed',
      'error_occurred': 'An error occurred',
      'retry': 'Retry',

      // Auth
      'login': 'Login',
      'register': 'Register',
      'student_id': 'Student ID',
      'password': 'Password',
      'full_name': 'Full Name',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': 'Don\'t have an account?',
      'already_have_account': 'Already have an account?',
      'loading': 'Loading...',

      // Home
      'welcome': 'Welcome',
      'today_plan': 'What do you want to learn today?',
      'start_practice': 'Start Practice',
      'my_progress': 'My Progress',
      'estimated_score': 'Estimated Score',
      'listening': 'Listening',
      'reading': 'Reading',
      'vocabulary': 'Vocabulary',
      'progress': 'Progress',
      'latest_ai_advice': 'Latest AI Advice',
      'view_detail_analysis': 'View Details',
      'recent_activity': 'Recent Activity',
      'view_analytics': 'View Analytics',
      'cards': 'cards',
      'just_now': 'Just now',
      'minutes_ago': 'mins ago',
      'hours_ago': 'hours ago',
      'days_ago': 'days ago',
      'my_class': 'My Class',
      'class': 'Class',
      'teacher': 'Teacher',
      'materials': 'Materials',

      // Practice
      'practice': 'Practice',
      'all': 'All',
      'questions': 'questions',
      'minutes': 'min',
      'start_now': 'Start Now',
      'no_tests_found': 'No tests found',
      'difficulty': 'Difficulty',
      'duration': 'Duration',
      'total_questions': 'Total Questions',
      'skills': 'Skills',
      'difficulty_level': 'Level',
      'continue': 'Continue',
      'practice_again': 'Practice Again',
      'target_score_dialog_title': 'Target Score',
      'target_score_dialog_desc': 'Set your TOEIC target for AI coaching.',
      'target_score_label': 'Target Score (0-990)',
      'target_score_hint': 'e.g. 850',
      'update': 'Update',
      'invalid_score_msg': 'Please enter a score between 0 and 990',
      'personal_achievement': 'Personal Achievements',
      'current_average_score_caps': 'CURRENT AVERAGE SCORE',
      'completed': 'Completed',
      'points_to_go': 'points to go!',
      'target_achieved': 'Target Achieved!',
      'no_performance_data_msg':
          'Take a test to start tracking your performance',
      'no_ai_assessments_msg': 'No AI assessments yet.',
      'achievement_points_label': 'Performance',

      // Progress
      'learning_journey': 'Learning Journey & AI Coach',
      'target_score': 'Target Score',
      'tests_taken': 'Tests Taken',
      'average_score': 'Average Score',
      'performance_history': 'Performance History',
      'milestone_achieved': 'Milestone Achieved',

      // Vocabulary
      'vocabulary_caps': 'VOCABULARY',
      'your_vocabulary_store': 'Your Vocabulary',
      'search_vocabulary_hint': 'Search vocabulary...',
      'empty_vocabulary_title': 'Vocabulary store is empty',
      'empty_vocabulary_desc': 'Save words from exercises to start practicing!',
      'no_results_found': 'No results found',
      'try_another_search': 'Try searching with another keyword.',
      'delete_vocabulary_title': 'Delete word?',
      'delete_vocabulary_confirm':
          'Are you sure you want to delete this card from your library?',
      'tap_to_flip': 'Tap to flip',
      'meaning_caps': 'MEANING',
      'example_caps': 'EXAMPLE',
    },
    'vi': {
      // General
      'settings': 'Cài đặt',
      'dark_mode': 'Chế độ tối',
      'language': 'Ngôn ngữ',
      'logout': 'Đăng xuất',
      'profile': 'Cá nhân',
      'profile_tab': 'Cá nhân',
      'home': 'Trang chủ',
      'edit_profile': 'Chỉnh sửa hồ sơ',
      'change_password': 'Đổi mật khẩu',
      'personal_information': 'Thông tin cá nhân',
      'account_settings': 'Cài đặt tài khoản',
      'confirm_logout': 'Xác nhận đăng xuất',
      'logout_message': 'Bạn có chắc chắn muốn đăng xuất?',
      'cancel': 'Hủy',
      'confirm': 'Đồng ý',
      'save_changes': 'Lưu thay đổi',
      'update_success': 'Cập nhật thành công!',
      'update_failed': 'Cập nhật thất bại',
      'error_occurred': 'Có lỗi xảy ra',
      'retry': 'Thử lại',

      // Auth
      'login': 'Đăng nhập',
      'register': 'Đăng ký',
      'student_id': 'Mã học viên',
      'password': 'Mật khẩu',
      'full_name': 'Họ và tên',
      'confirm_password': 'Xác nhận mật khẩu',
      'forgot_password': 'Quên mật khẩu?',
      'dont_have_account': 'Chưa có tài khoản?',
      'already_have_account': 'Đã có tài khoản?',
      'loading': 'Đang tải...',

      // Home
      'welcome': 'Chào mừng',
      'today_plan': 'Hôm nay bạn muốn học gì?',
      'start_practice': 'Bắt đầu luyện tập',
      'my_progress': 'Tiến độ của tôi',
      'estimated_score': 'Điểm dự tính',
      'listening': 'Listening',
      'reading': 'Reading',
      'vocabulary': 'Từ Vựng',
      'progress': 'Tiến độ',
      'latest_ai_advice': 'Chiến thuật AI mới nhất',
      'view_detail_analysis': 'Xem chi tiết',
      'recent_activity': 'Hoạt động gần đây',
      'view_analytics': 'Xem phân tích',
      'cards': 'thẻ',
      'just_now': 'Vừa xong',
      'minutes_ago': 'phút trước',
      'hours_ago': 'giờ trước',
      'days_ago': 'ngày trước',
      'my_class': 'Lớp học của tôi',
      'class': 'Lớp',
      'teacher': 'Giáo viên',
      'materials': 'Tài liệu',

      // Practice
      'practice': 'Luyện tập',
      'all': 'Tất cả',
      'questions': 'câu',
      'minutes': 'phút',
      'start_now': 'Làm bài ngay',
      'no_tests_found': 'Không tìm thấy đề ôn luyện nào',
      'difficulty': 'Độ khó',
      'duration': 'Thời gian',
      'total_questions': 'Tổng số câu',
      'skills': 'Kỹ năng',
      'difficulty_level': 'Cấp độ',
      'continue': 'Tiếp tục',
      'practice_again': 'Luyện tập lại',
      'target_score_dialog_title': 'Mục tiêu điểm số',
      'target_score_dialog_desc':
          'Thiết lập mục tiêu TOEIC để AI theo dõi lộ trình của bạn.',
      'target_score_label': 'Điểm mục tiêu (0-990)',
      'target_score_hint': 'VD: 850',
      'update': 'Cập nhật',
      'invalid_score_msg': 'Vui lòng nhập điểm từ 0 - 990',
      'personal_achievement': 'Điểm số cá nhân',
      'current_average_score_caps': 'ĐIỂM TRUNG BÌNH HIỆN TẠI',
      'completed': 'Hoàn thành',
      'points_to_go': 'điểm nữa!',
      'target_achieved': 'Đã hoàn thành mục tiêu!',
      'no_performance_data_msg': 'Hãy luyện tập để bắt đầu ghi lại điểm số',
      'no_ai_assessments_msg': 'Chưa có nhận xét AI nào.',
      'achievement_points_label': 'Điểm',

      // Progress
      'learning_journey': 'AI Coach',
      'target_score': 'Mục tiêu',
      'tests_taken': 'Số bài đã làm',
      'average_score': 'Điểm trung bình',
      'performance_history': 'Lịch sử phong độ',
      'milestone_achieved': 'Đã đạt cột mốc',

      // Vocabulary
      'vocabulary_caps': 'TỪ VỰNG',
      'your_vocabulary_store': 'Kho từ vựng của bạn',
      'search_vocabulary_hint': 'Tìm từ vựng...',
      'empty_vocabulary_title': 'Kho từ vựng trống',
      'empty_vocabulary_desc':
          'Lưu từ vựng từ các bài tập để bắt đầu ôn tập nhé!',
      'no_results_found': 'Không tìm thấy kết quả',
      'try_another_search': 'Thử tìm kiếm với từ khóa khác.',
      'delete_vocabulary_title': 'Xóa từ vựng?',
      'delete_vocabulary_confirm':
          'Bạn có chắc chắn muốn xóa thẻ này khỏi kho từ vựng không?',
      'tap_to_flip': 'Chạm để lật',
      'meaning_caps': 'NGHĨA',
      'example_caps': 'VÍ DỤ',
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

// Extension for cleaner access
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
}

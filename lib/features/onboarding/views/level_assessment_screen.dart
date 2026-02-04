import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../services/onboarding_service.dart';
import '../../auth/views/register_screen.dart';

/// Level Assessment Screen - Chọn trình độ TOEIC (1-5 bands)
class LevelAssessmentScreen extends StatefulWidget {
  const LevelAssessmentScreen({super.key});

  @override
  State<LevelAssessmentScreen> createState() => _LevelAssessmentScreenState();
}

class _LevelAssessmentScreenState extends State<LevelAssessmentScreen> {
  int? _selectedLevel;

  // 5 TOEIC Bands từ ảnh
  final List<ToeicLevel> _levels = const [
    ToeicLevel(
      level: 1,
      scoreRange: '0-250',
      name: 'Mất gốc',
      color: Color(0xFFFF9800), // Orange
      description: 'Xây dựng nền tảng ngữ pháp & từ vựng',
      icon: Icons.emoji_events_outlined,
    ),
    ToeicLevel(
      level: 2,
      scoreRange: '255-400',
      name: 'Elementary',
      color: Color(0xFF795548), // Brown
      description: 'Làm quen với format đề, nghe cơ bản',
      icon: Icons.school_outlined,
    ),
    ToeicLevel(
      level: 3,
      scoreRange: '405-600',
      name: 'Intermediate',
      color: Color(0xFF4CAF50), // Green
      description: 'Đủ điều kiện tốt nghiệp ĐH, giao tiếp cơ bản',
      icon: Icons.trending_up,
    ),
    ToeicLevel(
      level: 4,
      scoreRange: '605-850',
      name: 'Working Proficiency',
      color: Color(0xFF2196F3), // Blue
      description: 'Đủ chuẩn tập đoàn lớn, ngân hàng, hàng không',
      icon: Icons.work_outline,
    ),
    ToeicLevel(
      level: 5,
      scoreRange: '855-990',
      name: 'Advanced',
      color: Color(0xFFFFC107), // Yellow/Gold
      description: 'Thành thạo, giảng dạy, biên phiên dịch',
      icon: Icons.star,
    ),
  ];

  Future<void> _handleContinue() async {
    if (_selectedLevel == null) return;

    // Save level to local storage
    await OnboardingService.saveSelectedLevel(_selectedLevel!);
    await OnboardingService.markFirstLaunchComplete();

    if (!mounted) return;

    // Navigate to Register Screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Bạn cần luyện tập ở mức độ nào?',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chọn band điểm để nhận đề xuất phù hợp',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Level Cards List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: _levels.length,
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  final isSelected = _selectedLevel == level.level;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildLevelCard(level, isSelected),
                  );
                },
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedLevel != null ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Tiếp tục',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(ToeicLevel level, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLevel = level.level;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? level.color : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: level.color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: level.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(level.icon, color: level.color, size: 32),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: level.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      level.scoreRange,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Level Name
                  Text(
                    level.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    level.description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: level.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

/// TOEIC Level Model
class ToeicLevel {
  final int level;
  final String scoreRange;
  final String name;
  final Color color;
  final String description;
  final IconData icon;

  const ToeicLevel({
    required this.level,
    required this.scoreRange,
    required this.name,
    required this.color,
    required this.description,
    required this.icon,
  });
}

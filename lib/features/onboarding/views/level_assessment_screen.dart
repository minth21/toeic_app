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
  String? _selectedDifficulty;

  // 3 Difficulty Levels
  final List<ToeicLevel> _levels = const [
    ToeicLevel(
      id: 'EASY',
      scoreRange: '0-450',
      name: 'Easy',
      color: Color(0xFF4CAF50), // Green
      description: 'Dành cho người mới bắt đầu, mất gốc',
      icon: Icons.sentiment_satisfied_alt,
    ),
    ToeicLevel(
      id: 'MEDIUM',
      scoreRange: '450-750',
      name: 'Medium',
      color: Color(0xFFFF9800), // Orange
      description: 'Dành cho người có nền tảng, muốn cải thiện',
      icon: Icons.trending_up,
    ),
    ToeicLevel(
      id: 'HARD',
      scoreRange: '750-990',
      name: 'Hard',
      color: Color(0xFFF44336), // Red
      description: 'Dành cho người muốn chinh phục điểm cao',
      icon: Icons.whatshot,
    ),
  ];

  Future<void> _handleContinue() async {
    if (_selectedDifficulty == null) return;

    // Save difficulty to local storage
    await OnboardingService.saveSelectedDifficulty(_selectedDifficulty!);
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
                    'Bạn muốn luyện tập ở mức độ nào?',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chọn mức độ để nhận đề xuất phù hợp',
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
                  final isSelected = _selectedDifficulty == level.id;

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
                  onPressed: _selectedDifficulty != null
                      ? _handleContinue
                      : null,
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
          _selectedDifficulty = level.id;
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
                    color: level.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                color: level.color.withValues(alpha: 0.15),
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
  final String id;
  final String scoreRange;
  final String name;
  final Color color;
  final String description;
  final IconData icon;

  const ToeicLevel({
    required this.id,
    required this.scoreRange,
    required this.name,
    required this.color,
    required this.description,
    required this.icon,
  });
}

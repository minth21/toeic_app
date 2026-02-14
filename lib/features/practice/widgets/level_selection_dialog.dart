import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';

class LevelSelectionDialog extends StatefulWidget {
  final String? currentDifficulty;
  final Function(String) onDifficultySelected;

  const LevelSelectionDialog({
    super.key,
    this.currentDifficulty,
    required this.onDifficultySelected,
  });

  @override
  State<LevelSelectionDialog> createState() => _LevelSelectionDialogState();
}

class _LevelSelectionDialogState extends State<LevelSelectionDialog> {
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.currentDifficulty;
  }

  final List<ToeicLevel> _levels = const [
    ToeicLevel(
      id: 'EASY',
      scoreRange: '0-450',
      name: 'Easy',
      color: Color(0xFF4CAF50),
      description: 'Dành cho người mới bắt đầu, mất gốc',
      icon: Icons.sentiment_satisfied_alt,
    ),
    ToeicLevel(
      id: 'MEDIUM',
      scoreRange: '450-750',
      name: 'Medium',
      color: Color(0xFFFF9800),
      description: 'Dành cho người có nền tảng, muốn cải thiện',
      icon: Icons.trending_up,
    ),
    ToeicLevel(
      id: 'HARD',
      scoreRange: '750-990',
      name: 'Hard',
      color: Color(0xFFF44336),
      description: 'Dành cho người muốn chinh phục điểm cao',
      icon: Icons.whatshot,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Chọn mức độ luyện tập',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn có thể thay đổi bất cứ lúc nào',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Level List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: _levels.length,
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  final isSelected = _selectedDifficulty == level.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildLevelCard(level, isSelected),
                  );
                },
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedDifficulty != null
                      ? () {
                          widget.onDifficultySelected(_selectedDifficulty!);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Xác nhận',
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? level.color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: level.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(level.icon, color: level.color, size: 24),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: level.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          level.scoreRange,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          level.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Check icon
            if (isSelected)
              Icon(Icons.check_circle, color: level.color, size: 24),
          ],
        ),
      ),
    );
  }
}

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

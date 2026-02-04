import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../constants/app_constants.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../widgets/level_selection_dialog.dart';

/// Practice Screen - Hub luyện tập TOEIC với level selection
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int? _currentLevel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAndShowLevelSelection();
  }

  Future<void> _checkAndShowLevelSelection() async {
    // Get current user's level from AuthViewModel
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;

    setState(() {
      _currentLevel = user?.toeicLevel;
      _isLoading = false;
    });

    // Nếu chưa có level → Hiện dialog
    if (_currentLevel == null && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showLevelSelectionDialog();
      }
    }
  }

  Future<void> _showLevelSelectionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible:
          _currentLevel != null, // Chỉ cho dismiss nếu đã có level
      builder: (context) => LevelSelectionDialog(
        currentLevel: _currentLevel,
        onLevelSelected: _handleLevelSelected,
      ),
    );
  }

  Future<void> _handleLevelSelected(int level) async {
    setState(() => _isLoading = true);

    // Call API to update user's level
    final authViewModel = context.read<AuthViewModel>();
    final token = authViewModel.token;

    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/users/level'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'toeicLevel': level}),
      );

      if (response.statusCode == 200 && mounted) {
        // Refresh user data
        await authViewModel.refreshCurrentUser();

        setState(() {
          _currentLevel = level;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chọn mức độ: ${_getLevelName(level)}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi cập nhật mức độ'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Get level name from level number
  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Mất gốc';
      case 2:
        return 'Elementary';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Working Proficiency';
      case 5:
        return 'Advanced';
      default:
        return 'Level $level';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Luyện tập',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Nút đổi level
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Đổi mức độ',
            onPressed: _showLevelSelectionDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Hiển thị level hiện tại
          if (_currentLevel != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mức độ hiện tại',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          _getLevelName(_currentLevel!),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Danh sách đề thi (Coming soon)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 80,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Danh sách đề thi',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coming soon...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

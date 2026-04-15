import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../home/views/home_screen.dart';
import '../practice/views/practice_screen.dart';
import '../vocabulary/views/vocabulary_screen.dart';
import '../progress/views/progress_screen.dart';
import '../profile/views/profile_screen.dart';
import 'viewmodels/navigation_viewmodel.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

/// Main Navigation - Bottom navigation wrapper cho toàn bộ app
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  // Danh sách navigation items
  final List<NavigationItem> _navItems = const [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      labelKey: 'home',
      color: AppColors.primary,
    ),
    NavigationItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      labelKey: 'practice',
      color: Color(0xFF2196F3),
    ),
    NavigationItem(
      icon: Icons.style_outlined,
      activeIcon: Icons.style,
      labelKey: 'vocabulary',
      color: Color(0xFFE91E63),
    ),
    NavigationItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      labelKey: 'progress',
      color: Color(0xFFFF9800),
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      labelKey: 'profile_tab',
      color: Color(0xFF9C27B0),
    ),
  ];

  void _onTabTapped(BuildContext context, int index) {
    context.read<NavigationViewModel>().setIndex(index);
  }

  // Get current screen based on index
  Widget _getCurrentScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const PracticeScreen();
      case 2:
        return const VocabularyScreen();
      case 3:
        return const ProgressScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navVM = context.watch<NavigationViewModel>();
    final currentIndex = navVM.currentIndex;

    return Scaffold(
      body: _getCurrentScreen(currentIndex), // Only render current screen
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onTabTapped(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: _navItems.map((item) {
            final isSelected = _navItems.indexOf(item) == currentIndex;
            return BottomNavigationBarItem(
              icon: Icon(isSelected ? item.activeIcon : item.icon, size: 24),
              label: context.tr(item.labelKey),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Navigation Item Model
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  final Color color;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    required this.color,
  });
}

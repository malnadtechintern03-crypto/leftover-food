import 'package:flutter/material.dart';
import '../../features/expiry_calendar/presentation/screens/expiry_calendar_screen.dart';
import '../../features/food_inventory/presentation/screens/home_screen.dart';
import '../../features/food_inventory/presentation/screens/pantry_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/recipes/presentation/screens/recipes_screen.dart';
import '../theme/color_palette.dart';

/// Main Navigation Scaffold featuring 5-tab Bottom Navigation with lazy tab loading
class MainNavigationScaffold extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScaffold({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  late int _currentIndex;
  final Set<int> _visitedTabs = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visitedTabs.add(_currentIndex);
  }

  void _switchTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        _visitedTabs.add(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _visitedTabs.contains(0)
              ? HomeScreen(
                  onOpenPantryTab: () => _switchTab(1),
                  onOpenCalendarTab: () => _switchTab(2),
                )
              : const SizedBox.shrink(),
          _visitedTabs.contains(1)
              ? const PantryScreen()
              : const SizedBox.shrink(),
          _visitedTabs.contains(2)
              ? const ExpiryCalendarScreen()
              : const SizedBox.shrink(),
          _visitedTabs.contains(3)
              ? const RecipesScreen()
              : const SizedBox.shrink(),
          _visitedTabs.contains(4)
              ? const ProfileScreen()
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
          border: Border(
            top: BorderSide(
              color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: _currentIndex == 0,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.shopping_basket_outlined,
                    label: 'Groceries',
                    isSelected: _currentIndex == 1,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: Icons.calendar_month_rounded,
                    label: 'Calendar',
                    isSelected: _currentIndex == 2,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Recipes',
                    isSelected: _currentIndex == 3,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 4,
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    isSelected: _currentIndex == 4,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeColor = ColorPalette.freshEmerald;
    final inactiveColor = isDark ? ColorPalette.darkTextTertiary : const Color(0xFF9CA3AF);

    return InkWell(
      onTap: () => _switchTab(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

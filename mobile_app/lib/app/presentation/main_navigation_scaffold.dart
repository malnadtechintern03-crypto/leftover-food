import 'package:flutter/material.dart';
import '../../features/expiry_calendar/presentation/screens/expiry_calendar_screen.dart';
import '../../features/food_inventory/presentation/screens/home_screen.dart';
import '../../features/food_inventory/presentation/screens/pantry_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../theme/color_palette.dart';

/// Main Navigation Scaffold featuring 4-tab Bottom Navigation with lazy tab loading
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
              ? const ProfileScreen()
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131F2E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF243B55)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                if (!isDark)
                  BoxShadow(
                    color: ColorPalette.freshEmerald.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                  label: 'Home',
                  isSelected: _currentIndex == 0,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  icon: _currentIndex == 1 ? Icons.shopping_basket_rounded : Icons.shopping_basket_outlined,
                  label: 'Groceries',
                  isSelected: _currentIndex == 1,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  isSelected: _currentIndex == 2,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 3,
                  icon: _currentIndex == 3 ? Icons.person_rounded : Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: _currentIndex == 3,
                  isDark: isDark,
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
    // Primary green accent
    const activeColor = ColorPalette.freshEmerald;

    // Unselected subtle dark gray/green
    final inactiveIconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inactiveTextColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final activeTextColor = isDark ? ColorPalette.freshEmerald : const Color(0xFF047857);

    // Soft light-green circular/rounded background for selected item
    final selectedBgColor = isDark
        ? const Color(0xFF10B981).withValues(alpha: 0.18)
        : const Color(0xFFE8F5E9);

    return Expanded(
      child: Semantics(
        label: label,
        selected: isSelected,
        button: true,
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _switchTab(index),
              borderRadius: BorderRadius.circular(22),
              splashColor: activeColor.withValues(alpha: 0.12),
              highlightColor: Colors.transparent,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? selectedBgColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                    ? ColorPalette.freshEmerald.withValues(alpha: 0.3)
                                    : const Color(0xFFA7F3D0))
                                : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: AnimatedScale(
                          scale: isSelected ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOutCubic,
                          child: Icon(
                            icon,
                            size: 22,
                            color: isSelected ? activeColor : inactiveIconColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? activeTextColor : inactiveTextColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../features/expiry_calendar/presentation/screens/expiry_calendar_screen.dart';
import '../../features/food_inventory/presentation/screens/home_screen.dart';
import '../../features/food_inventory/presentation/screens/pantry_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

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
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F3B2C), // Deep dark green
                  Color(0xFF062319), // Dark forest shadow
                ],
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.22), // Subtle emerald glow
                  blurRadius: 16,
                  spreadRadius: -1,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                  label: 'Home',
                  isSelected: _currentIndex == 0,
                ),
                _buildNavItem(
                  index: 1,
                  icon: _currentIndex == 1 ? Icons.shopping_basket_rounded : Icons.shopping_basket_outlined,
                  label: 'Groceries',
                  isSelected: _currentIndex == 1,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  isSelected: _currentIndex == 2,
                ),
                _buildNavItem(
                  index: 3,
                  icon: _currentIndex == 3 ? Icons.person_rounded : Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: _currentIndex == 3,
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
  }) {
    const activeFgColor = Color(0xFF064E3B);
    const inactiveIconColor = Color(0xFFD1D5DB);
    const inactiveTextColor = Color(0xFFE5E7EB);
    const activePillColor = Color(0xFFA7F3D0); // Clean light green rounded rectangle

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _switchTab(index),
            borderRadius: BorderRadius.circular(20),
            splashColor: activePillColor.withValues(alpha: 0.2),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? activePillColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activePillColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: isSelected ? activeFgColor : inactiveIconColor,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? activeFgColor : inactiveTextColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

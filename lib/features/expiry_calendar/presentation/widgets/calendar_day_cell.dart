import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../food_inventory/domain/entities/food_item.dart';
import '../../../food_inventory/domain/entities/food_status.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<FoodItem> items;
  final int warningDays;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.items,
    required this.warningDays,
    required this.onTap,
  });

  Color _getStatusColor(FoodItem item) {
    if (item.isConsumed) {
      return const Color(0xFF94A3B8); // Slate grey for used
    }
    final status = item.getStatus(warningDays: warningDays);
    switch (status) {
      case FoodStatus.fresh:
        return ColorPalette.freshEmerald;
      case FoodStatus.expiringSoon:
        return ColorPalette.warningAmber;
      case FoodStatus.expired:
        return ColorPalette.expiredRed;
      case FoodStatus.consumed:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseTextColor = isCurrentMonth
        ? (isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary)
        : (isDark ? ColorPalette.darkTextTertiary : const Color(0xFFD1D5DB));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? ColorPalette.freshEmerald.withValues(alpha: 0.22)
                    : ColorPalette.freshEmerald.withValues(alpha: 0.14))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? ColorPalette.freshEmerald
                  : (isToday
                      ? ColorPalette.freshEmerald.withValues(alpha: 0.5)
                      : Colors.transparent),
              width: isSelected ? 1.8 : (isToday ? 1.2 : 0),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Day number circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? ColorPalette.freshEmerald
                      : (isSelected && !isToday
                          ? ColorPalette.freshEmerald.withValues(alpha: 0.2)
                          : Colors.transparent),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: (isToday || isSelected) ? FontWeight.w800 : FontWeight.w600,
                      color: isToday
                          ? Colors.white
                          : (isSelected
                              ? (isDark ? ColorPalette.freshEmerald : ColorPalette.freshEmeraldDark)
                              : baseTextColor),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 3),

              // Expiry Indicator Dots
              if (items.isNotEmpty)
                _buildIndicatorDots(isDark)
              else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorDots(bool isDark) {
    if (items.length <= 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final color = _getStatusColor(item);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // More than 3 items: show 2 dots + count badge
    final firstTwo = items.take(2).toList();
    final remainingCount = items.length - 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...firstTwo.map((item) {
          final color = _getStatusColor(item);
          return Container(
            margin: const EdgeInsets.only(right: 2),
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );
        }),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
          decoration: BoxDecoration(
            color: isDark ? ColorPalette.darkSurfaceHighlight : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '+$remainingCount',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

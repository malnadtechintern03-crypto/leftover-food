import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../domain/entities/food_filter.dart';

/// Clean Sort Options Bottom Sheet for the "Sort >" action
class FoodSortSheet extends StatelessWidget {
  final FoodSortOption currentSort;
  final ValueChanged<FoodSortOption> onSortSelected;

  const FoodSortSheet({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required FoodSortOption currentSort,
    required ValueChanged<FoodSortOption> onSortSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FoodSortSheet(
        currentSort: currentSort,
        onSortSelected: onSortSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      (
        option: FoodSortOption.expiryDateAsc,
        label: 'Expiry Date (Soonest First)',
        icon: Icons.hourglass_top_rounded,
      ),
      (
        option: FoodSortOption.nameAsc,
        label: 'Ingredient Name (A - Z)',
        icon: Icons.sort_by_alpha_rounded,
      ),
      (
        option: FoodSortOption.dateAddedDesc,
        label: 'Recently Added',
        icon: Icons.calendar_today_rounded,
      ),
      (
        option: FoodSortOption.quantityDesc,
        label: 'Highest Quantity',
        icon: Icons.inventory_2_outlined,
      ),
      (
        option: FoodSortOption.expiryDateDesc,
        label: 'Expiry Date (Latest First)',
        icon: Icons.hourglass_bottom_rounded,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Sort Ingredients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? ColorPalette.darkTextPrimary
                      : ColorPalette.lightTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((item) {
              final isSelected = item.option == currentSort;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(
                  item.icon,
                  color: isSelected
                      ? ColorPalette.freshEmerald
                      : (isDark
                          ? ColorPalette.darkTextSecondary
                          : ColorPalette.lightTextSecondary),
                  size: 20,
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? ColorPalette.freshEmerald
                        : (isDark
                            ? ColorPalette.darkTextPrimary
                            : ColorPalette.lightTextPrimary),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: ColorPalette.freshEmerald,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  onSortSelected(item.option);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

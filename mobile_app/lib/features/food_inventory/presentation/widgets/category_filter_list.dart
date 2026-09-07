import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../domain/entities/food_category.dart';

/// Horizontal scrolling category selector capsules with Cyber Aurora glow
class CategoryFilterList extends StatelessWidget {
  final FoodCategory? selectedCategory;
  final ValueChanged<FoodCategory?> onCategorySelected;

  const CategoryFilterList({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All Categories" Pill
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selectedCategory == null
                  ? (isDark ? ColorPalette.primaryViolet.withValues(alpha: 0.35) : ColorPalette.primaryVioletLight)
                  : (isDark ? ColorPalette.darkCard : ColorPalette.lightCard),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: selectedCategory == null
                      ? ColorPalette.primaryViolet
                      : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
                  width: selectedCategory == null ? 1.6 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onCategorySelected(null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 15,
                        color: selectedCategory == null
                            ? (isDark ? ColorPalette.electricMint : ColorPalette.primaryVioletDark)
                            : (isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'All',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: selectedCategory == null ? FontWeight.w900 : FontWeight.w600,
                          color: selectedCategory == null
                              ? (isDark ? Colors.white : ColorPalette.primaryVioletDark)
                              : (isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Categories
          ...FoodCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: isSelected
                    ? category.color.withValues(alpha: isDark ? 0.30 : 0.18)
                    : (isDark ? ColorPalette.darkCard : ColorPalette.lightCard),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected
                        ? category.color
                        : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
                    width: isSelected ? 1.6 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onCategorySelected(category),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 15,
                          color: category.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? Colors.white : category.color)
                                : (isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';

/// Supported categories for grocery and pantry items
enum FoodCategory {
  grainsAndPulses(
    'Grains & Pulses',
    Icons.grain_rounded,
    ColorPalette.categoryGrains,
  ),
  flourAndBaking(
    'Flour & Baking',
    Icons.bakery_dining_rounded,
    ColorPalette.categoryFlour,
  ),
  dairy(
    'Dairy',
    Icons.water_drop_rounded,
    ColorPalette.categoryDairy,
  ),
  spices(
    'Spices',
    Icons.scatter_plot_rounded,
    ColorPalette.categorySpices,
  ),
  oils(
    'Oils & Ghee',
    Icons.opacity_rounded,
    ColorPalette.categoryOils,
  ),
  snacksAndPackaged(
    'Snacks & Packaged',
    Icons.cookie_rounded,
    ColorPalette.categorySnacks,
  ),
  beverages(
    'Beverages',
    Icons.local_cafe_rounded,
    ColorPalette.categoryBeverages,
  ),
  other(
    'Other Groceries',
    Icons.inventory_2_rounded,
    ColorPalette.categoryOther,
  );

  final String label;
  final IconData icon;
  final Color color;

  const FoodCategory(this.label, this.icon, this.color);

  /// All valid grocery category enum names
  static List<String> get groceryCategoryNames =>
      FoodCategory.values.map((e) => e.name).toList();

  /// Checks if a string represents an allowed grocery category (case-insensitive)
  static bool isAllowedGrocery(String val) {
    final lower = val.trim().toLowerCase();
    // Exclude legacy food categories
    if (lower == 'vegetables' ||
        lower == 'fruits' ||
        lower == 'cookedfood' ||
        lower == 'cooked food' ||
        lower == 'drinks') {
      return false;
    }
    return FoodCategory.values.any(
      (e) =>
          e.name.toLowerCase() == lower ||
          e.label.toLowerCase() == lower,
    );
  }

  static FoodCategory fromString(String val) {
    final lower = val.trim().toLowerCase();
    // Safe mapping for legacy strings if encountered
    if (lower == 'drinks') return FoodCategory.beverages;

    return FoodCategory.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == lower ||
          e.label.toLowerCase() == lower,
      orElse: () => FoodCategory.other,
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';

/// Supported categories for pantry, grocery, and universal household products
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
  medicines(
    'Medicines & First Aid',
    Icons.medication_rounded,
    Color(0xFFEF4444),
  ),
  personalCare(
    'Personal Care & Beauty',
    Icons.face_retouching_natural_rounded,
    Color(0xFFEC4899),
  ),
  householdCleaning(
    'Cleaning & Household',
    Icons.cleaning_services_rounded,
    Color(0xFF3B82F6),
  ),
  petSupplies(
    'Pet Supplies',
    Icons.pets_rounded,
    Color(0xFFF97316),
  ),
  babyCare(
    'Baby Care',
    Icons.child_care_rounded,
    Color(0xFF8B5CF6),
  ),
  stationeryAndOffice(
    'Stationery & Office',
    Icons.edit_note_rounded,
    Color(0xFF14B8A6),
  ),
  electronicsAndHardware(
    'Electronics & Batteries',
    Icons.battery_charging_full_rounded,
    Color(0xFF6366F1),
  ),
  other(
    'Other Products',
    Icons.inventory_2_rounded,
    ColorPalette.categoryOther,
  );

  final String label;
  final IconData icon;
  final Color color;

  const FoodCategory(this.label, this.icon, this.color);

  /// All valid category enum names
  static List<String> get groceryCategoryNames =>
      FoodCategory.values.map((e) => e.name).toList();

  /// Checks if a string represents an allowed category (case-insensitive)
  static bool isAllowedGrocery(String val) {
    final lower = val.trim().toLowerCase();
    // Exclude legacy obsolete food strings
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
    // Safe mapping for legacy and alternate strings
    if (lower == 'drinks') return FoodCategory.beverages;
    if (lower.contains('medicine') || lower.contains('pharma') || lower.contains('drug')) return FoodCategory.medicines;
    if (lower.contains('beauty') || lower.contains('cosmetic') || lower.contains('personal') || lower.contains('shampoo') || lower.contains('skin')) return FoodCategory.personalCare;
    if (lower.contains('clean') || lower.contains('detergent') || lower.contains('wash') || lower.contains('household')) return FoodCategory.householdCleaning;
    if (lower.contains('pet') || lower.contains('dog') || lower.contains('cat')) return FoodCategory.petSupplies;
    if (lower.contains('baby') || lower.contains('diaper') || lower.contains('infant')) return FoodCategory.babyCare;
    if (lower.contains('battery') || lower.contains('electronic') || lower.contains('hardware')) return FoodCategory.electronicsAndHardware;
    if (lower.contains('stationery') || lower.contains('office') || lower.contains('pen') || lower.contains('paper')) return FoodCategory.stationeryAndOffice;

    return FoodCategory.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == lower ||
          e.label.toLowerCase() == lower,
      orElse: () => FoodCategory.other,
    );
  }
}

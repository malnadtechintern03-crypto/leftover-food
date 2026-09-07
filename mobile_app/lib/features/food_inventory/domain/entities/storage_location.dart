import 'package:flutter/material.dart';

/// Supported storage locations for groceries
enum StorageLocation {
  pantry('Pantry', Icons.kitchen_rounded, Color(0xFF10B981)),
  fridge('Fridge', Icons.ac_unit_rounded, Color(0xFF0284C7)),
  freezer('Freezer', Icons.severe_cold_rounded, Color(0xFF6366F1)),
  kitchenCabinet('Kitchen Cabinet', Icons.inventory_2_rounded, Color(0xFFF59E0B)),
  other('Other', Icons.category_rounded, Color(0xFF8B5CF6));

  final String label;
  final IconData icon;
  final Color color;

  const StorageLocation(this.label, this.icon, this.color);

  static StorageLocation fromString(String? val) {
    if (val == null) return StorageLocation.pantry;
    final lower = val.trim().toLowerCase();
    return StorageLocation.values.firstWhere(
      (e) => e.name.toLowerCase() == lower || e.label.toLowerCase() == lower,
      orElse: () => StorageLocation.pantry,
    );
  }
}

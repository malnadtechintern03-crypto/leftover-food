import '../../../food_inventory/domain/entities/food_category.dart';
import '../../../food_inventory/domain/entities/food_unit.dart';

enum ShoppingPriority {
  low('Low', 1),
  medium('Medium', 2),
  high('High', 3);

  final String label;
  final int value;

  const ShoppingPriority(this.label, this.value);

  static ShoppingPriority fromString(String? val) {
    if (val == null) return ShoppingPriority.medium;
    final lower = val.trim().toLowerCase();
    return ShoppingPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == lower || e.label.toLowerCase() == lower,
      orElse: () => ShoppingPriority.medium,
    );
  }
}

/// Domain entity representing a grocery shopping item
class ShoppingItem {
  final String id;
  final String name;
  final double quantity;
  final FoodUnit unit;
  final FoodCategory category;
  final bool isPurchased;
  final ShoppingPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.category = FoodCategory.other,
    this.isPurchased = false,
    this.priority = ShoppingPriority.medium,
    required this.createdAt,
    required this.updatedAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    double? quantity,
    FoodUnit? unit,
    FoodCategory? category,
    bool? isPurchased,
    ShoppingPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          quantity == other.quantity &&
          unit == other.unit &&
          category == other.category &&
          isPurchased == other.isPurchased &&
          priority == other.priority;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      quantity.hashCode ^
      unit.hashCode ^
      category.hashCode ^
      isPurchased.hashCode ^
      priority.hashCode;
}

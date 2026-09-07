import '../../../food_inventory/domain/entities/food_category.dart';
import '../../../food_inventory/domain/entities/food_unit.dart';
import '../../domain/entities/shopping_item.dart';

class ShoppingItemModel extends ShoppingItem {
  const ShoppingItemModel({
    required super.id,
    required super.name,
    required super.quantity,
    required super.unit,
    super.category = FoodCategory.other,
    super.isPurchased = false,
    super.priority = ShoppingPriority.medium,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ShoppingItemModel.fromEntity(ShoppingItem entity) {
    return ShoppingItemModel(
      id: entity.id,
      name: entity.name,
      quantity: entity.quantity,
      unit: entity.unit,
      category: entity.category,
      isPurchased: entity.isPurchased,
      priority: entity.priority,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) {
    return ShoppingItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: FoodUnit.fromString(map['unit'] as String),
      category: FoodCategory.fromString(map['category'] as String),
      isPurchased: (map['is_purchased'] as int? ?? 0) == 1,
      priority: ShoppingPriority.fromString(map['priority'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit.name,
      'category': category.name,
      'is_purchased': isPurchased ? 1 : 0,
      'priority': priority.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ShoppingItemModel.fromJson(Map<String, dynamic> json) =>
      ShoppingItemModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}

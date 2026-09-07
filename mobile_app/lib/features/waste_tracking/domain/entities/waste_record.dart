import '../../../food_inventory/domain/entities/food_category.dart';
import '../../../food_inventory/domain/entities/food_unit.dart';

enum WasteReason {
  expiredBeforeUse('Expired Before Use'),
  overbought('Overbought'),
  storedIncorrectly('Stored Incorrectly'),
  damagedPackaging('Damaged Packaging'),
  other('Other');

  final String label;
  const WasteReason(this.label);

  static WasteReason fromString(String? val) {
    if (val == null) return WasteReason.expiredBeforeUse;
    final lower = val.trim().toLowerCase();
    return WasteReason.values.firstWhere(
      (e) => e.name.toLowerCase() == lower || e.label.toLowerCase() == lower,
      orElse: () => WasteReason.expiredBeforeUse,
    );
  }
}

class WasteRecord {
  final String id;
  final String? foodItemId;
  final String name;
  final FoodCategory category;
  final double quantity;
  final FoodUnit unit;
  final WasteReason reason;
  final double? cost;
  final DateTime wastedAt;

  const WasteRecord({
    required this.id,
    this.foodItemId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.reason,
    this.cost,
    required this.wastedAt,
  });

  WasteRecord copyWith({
    String? id,
    String? foodItemId,
    String? name,
    FoodCategory? category,
    double? quantity,
    FoodUnit? unit,
    WasteReason? reason,
    double? cost,
    DateTime? wastedAt,
  }) {
    return WasteRecord(
      id: id ?? this.id,
      foodItemId: foodItemId ?? this.foodItemId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      reason: reason ?? this.reason,
      cost: cost ?? this.cost,
      wastedAt: wastedAt ?? this.wastedAt,
    );
  }
}

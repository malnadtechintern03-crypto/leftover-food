import '../../../food_inventory/domain/entities/food_category.dart';
import '../../../food_inventory/domain/entities/food_unit.dart';
import '../../domain/entities/waste_record.dart';

class WasteRecordModel extends WasteRecord {
  const WasteRecordModel({
    required super.id,
    super.foodItemId,
    required super.name,
    required super.category,
    required super.quantity,
    required super.unit,
    required super.reason,
    super.cost,
    required super.wastedAt,
  });

  factory WasteRecordModel.fromEntity(WasteRecord entity) {
    return WasteRecordModel(
      id: entity.id,
      foodItemId: entity.foodItemId,
      name: entity.name,
      category: entity.category,
      quantity: entity.quantity,
      unit: entity.unit,
      reason: entity.reason,
      cost: entity.cost,
      wastedAt: entity.wastedAt,
    );
  }

  factory WasteRecordModel.fromMap(Map<String, dynamic> map) {
    return WasteRecordModel(
      id: map['id'] as String,
      foodItemId: map['food_item_id'] as String?,
      name: map['name'] as String,
      category: FoodCategory.fromString(map['category'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      unit: FoodUnit.fromString(map['unit'] as String),
      reason: WasteReason.fromString(map['reason'] as String?),
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      wastedAt: DateTime.parse(map['wasted_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_item_id': foodItemId,
      'name': name,
      'category': category.name,
      'quantity': quantity,
      'unit': unit.name,
      'reason': reason.name,
      'cost': cost,
      'wasted_at': wastedAt.toIso8601String(),
    };
  }

  factory WasteRecordModel.fromJson(Map<String, dynamic> json) =>
      WasteRecordModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}

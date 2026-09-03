import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/storage_location.dart';

/// Data model representing a FoodItem in SQLite and JSON with full backwards compatibility
class FoodItemModel extends FoodItem {
  const FoodItemModel({
    required super.id,
    required super.name,
    required super.category,
    required super.purchaseDate,
    required super.expiryDate,
    required super.remainingQuantity,
    required super.unit,
    super.notes,
    super.imagePath,
    super.isConsumed = false,
    required super.createdAt,
    required super.updatedAt,
    super.minimumStock,
    super.price,
    super.storageLocation = StorageLocation.pantry,
    super.isFavorite = false,
    super.isRecurring = false,
    super.recurringIntervalDays,
    super.nextReminderDate,
    super.barcode,
  });

  factory FoodItemModel.fromEntity(FoodItem entity) {
    return FoodItemModel(
      id: entity.id,
      name: entity.name,
      category: entity.category,
      purchaseDate: entity.purchaseDate,
      expiryDate: entity.expiryDate,
      remainingQuantity: entity.remainingQuantity,
      unit: entity.unit,
      notes: entity.notes,
      imagePath: entity.imagePath,
      isConsumed: entity.isConsumed,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      minimumStock: entity.minimumStock,
      price: entity.price,
      storageLocation: entity.storageLocation,
      isFavorite: entity.isFavorite,
      isRecurring: entity.isRecurring,
      recurringIntervalDays: entity.recurringIntervalDays,
      nextReminderDate: entity.nextReminderDate,
      barcode: entity.barcode,
    );
  }

  factory FoodItemModel.fromMap(Map<String, dynamic> map) {
    return FoodItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: FoodCategory.fromString(map['category'] as String),
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      remainingQuantity: (map['remaining_quantity'] as num).toDouble(),
      unit: FoodUnit.fromString(map['unit'] as String),
      notes: map['notes'] as String?,
      imagePath: map['image_path'] as String?,
      isConsumed: (map['is_consumed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      minimumStock: map['minimum_stock'] != null
          ? (map['minimum_stock'] as num).toDouble()
          : null,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      storageLocation:
          StorageLocation.fromString(map['storage_location'] as String?),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurringIntervalDays: map['recurring_interval'] as int?,
      nextReminderDate: map['next_reminder_date'] != null
          ? DateTime.tryParse(map['next_reminder_date'] as String)
          : null,
      barcode: map['barcode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'purchase_date': purchaseDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'remaining_quantity': remainingQuantity,
      'unit': unit.name,
      'notes': notes,
      'image_path': imagePath,
      'is_consumed': isConsumed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'minimum_stock': minimumStock,
      'price': price,
      'storage_location': storageLocation.name,
      'is_favorite': isFavorite ? 1 : 0,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_interval': recurringIntervalDays,
      'next_reminder_date': nextReminderDate?.toIso8601String(),
      'barcode': barcode,
    };
  }

  factory FoodItemModel.fromJson(Map<String, dynamic> json) =>
      FoodItemModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}

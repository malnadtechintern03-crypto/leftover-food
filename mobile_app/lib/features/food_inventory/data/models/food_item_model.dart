import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/storage_location.dart';

/// Data model representing a FoodItem / Universal Product in SQLite and JSON with full backwards compatibility
class FoodItemModel extends FoodItem {
  const FoodItemModel({
    required super.id,
    required super.name,
    super.brand,
    super.barcode,
    required super.category,
    super.subcategory,
    required super.purchaseDate,
    super.manufacturingDate,
    super.expiryDate,
    super.reminderDate,
    super.reminderEnabled = true,
    super.reminderDaysBefore = const [7],
    super.notificationId,
    super.expiryStatus,
    super.lastNotificationSent,
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
  });

  factory FoodItemModel.fromEntity(FoodItem entity) {
    return FoodItemModel(
      id: entity.id,
      name: entity.name,
      brand: entity.brand,
      barcode: entity.barcode,
      category: entity.category,
      subcategory: entity.subcategory,
      purchaseDate: entity.purchaseDate,
      manufacturingDate: entity.manufacturingDate,
      expiryDate: entity.expiryDate,
      reminderDate: entity.reminderDate,
      reminderEnabled: entity.reminderEnabled,
      reminderDaysBefore: entity.reminderDaysBefore,
      notificationId: entity.notificationId,
      expiryStatus: entity.expiryStatus,
      lastNotificationSent: entity.lastNotificationSent,
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
    );
  }

  factory FoodItemModel.fromMap(Map<String, dynamic> map) {
    // Parse reminder days before
    List<int> reminderDays = const [7];
    final rawDays = map['reminder_days_before'];
    if (rawDays is String && rawDays.trim().isNotEmpty) {
      reminderDays = rawDays
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
      if (reminderDays.isEmpty) reminderDays = const [7];
    } else if (rawDays is List) {
      reminderDays = rawDays.map((e) => int.tryParse(e.toString())).whereType<int>().toList();
      if (reminderDays.isEmpty) reminderDays = const [7];
    }

    final rawExpiry = map['expiry_date'];
    DateTime? parsedExpiry;
    if (rawExpiry != null && rawExpiry.toString().trim().isNotEmpty) {
      parsedExpiry = DateTime.tryParse(rawExpiry.toString());
    }

    final rawMfg = map['manufacturing_date'];
    DateTime? parsedMfg;
    if (rawMfg != null && rawMfg.toString().trim().isNotEmpty) {
      parsedMfg = DateTime.tryParse(rawMfg.toString());
    }

    final rawReminder = map['reminder_date'];
    DateTime? parsedReminder;
    if (rawReminder != null && rawReminder.toString().trim().isNotEmpty) {
      parsedReminder = DateTime.tryParse(rawReminder.toString());
    }

    final rawLastNotif = map['last_notification_sent'];
    DateTime? parsedLastNotif;
    if (rawLastNotif != null && rawLastNotif.toString().trim().isNotEmpty) {
      parsedLastNotif = DateTime.tryParse(rawLastNotif.toString());
    }

    return FoodItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      barcode: map['barcode'] as String?,
      category: FoodCategory.fromString(map['category'] as String),
      subcategory: map['subcategory'] as String?,
      purchaseDate: DateTime.tryParse(map['purchase_date']?.toString() ?? '') ?? DateTime.now(),
      manufacturingDate: parsedMfg,
      expiryDate: parsedExpiry,
      reminderDate: parsedReminder,
      reminderEnabled: (map['reminder_enabled'] as int? ?? 1) == 1,
      reminderDaysBefore: reminderDays,
      notificationId: map['notification_id'] as int?,
      expiryStatus: map['expiry_status'] as String?,
      lastNotificationSent: parsedLastNotif,
      remainingQuantity: (map['remaining_quantity'] as num).toDouble(),
      unit: FoodUnit.fromString(map['unit'] as String),
      notes: map['notes'] as String?,
      imagePath: map['image_path'] as String?,
      isConsumed: (map['is_consumed'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'category': category.name,
      'subcategory': subcategory,
      'purchase_date': purchaseDate.toIso8601String(),
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'reminder_date': reminderDate?.toIso8601String(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_days_before': reminderDaysBefore.join(','),
      'notification_id': notificationId,
      'expiry_status': getStatus().label,
      'last_notification_sent': lastNotificationSent?.toIso8601String(),
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
    };
  }

  factory FoodItemModel.fromJson(Map<String, dynamic> json) =>
      FoodItemModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}


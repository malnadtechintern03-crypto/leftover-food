import '../../../../core/utils/expiry_calculator.dart';
import 'food_category.dart';
import 'food_status.dart';
import 'food_unit.dart';
import 'storage_location.dart';

/// Core domain entity representing a grocery item in pantry/kitchen
class FoodItem {
  final String id;
  final String name;
  final FoodCategory category;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final double remainingQuantity;
  final FoodUnit unit;
  final String? notes;
  final String? imagePath;
  final bool isConsumed;
  final DateTime createdAt;
  final DateTime updatedAt;

  // New Grocery Features
  final double? minimumStock;
  final double? price;
  final StorageLocation storageLocation;
  final bool isFavorite;
  final bool isRecurring;
  final int? recurringIntervalDays;
  final DateTime? nextReminderDate;
  final String? barcode;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.purchaseDate,
    required this.expiryDate,
    required this.remainingQuantity,
    required this.unit,
    this.notes,
    this.imagePath,
    this.isConsumed = false,
    required this.createdAt,
    required this.updatedAt,
    this.minimumStock,
    this.price,
    this.storageLocation = StorageLocation.pantry,
    this.isFavorite = false,
    this.isRecurring = false,
    this.recurringIntervalDays,
    this.nextReminderDate,
    this.barcode,
  });

  /// Computes active FoodStatus based on warning day threshold
  FoodStatus getStatus({int warningDays = 2, DateTime? referenceDate}) {
    if (isConsumed || remainingQuantity <= 0) {
      return FoodStatus.consumed;
    }
    final days = daysUntilExpiry(referenceDate: referenceDate);
    if (days < 0) {
      return FoodStatus.expired;
    }
    if (days <= warningDays) {
      return FoodStatus.expiringSoon;
    }
    return FoodStatus.fresh;
  }

  /// Whether current active quantity is at or below minimum stock threshold
  bool isLowStock() {
    if (isConsumed || minimumStock == null || minimumStock! <= 0) return false;
    return remainingQuantity <= minimumStock!;
  }

  int daysUntilExpiry({DateTime? referenceDate}) {
    return ExpiryCalculator.daysRemaining(expiryDate, referenceDate: referenceDate);
  }

  int daysStored({DateTime? referenceDate}) {
    return ExpiryCalculator.daysStored(purchaseDate, referenceDate: referenceDate);
  }

  bool isExpired({DateTime? referenceDate}) {
    return daysUntilExpiry(referenceDate: referenceDate) < 0;
  }

  bool isExpiringSoon({int warningDays = 2, DateTime? referenceDate}) {
    final days = daysUntilExpiry(referenceDate: referenceDate);
    return days >= 0 && days <= warningDays;
  }

  double freshnessProgress({DateTime? referenceDate}) {
    return ExpiryCalculator.calculateFreshnessProgress(
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      referenceDate: referenceDate,
    );
  }

  FoodItem copyWith({
    String? id,
    String? name,
    FoodCategory? category,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    double? remainingQuantity,
    FoodUnit? unit,
    String? notes,
    String? imagePath,
    bool? isConsumed,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? minimumStock,
    double? price,
    StorageLocation? storageLocation,
    bool? isFavorite,
    bool? isRecurring,
    int? recurringIntervalDays,
    DateTime? nextReminderDate,
    String? barcode,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      isConsumed: isConsumed ?? this.isConsumed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      minimumStock: minimumStock ?? this.minimumStock,
      price: price ?? this.price,
      storageLocation: storageLocation ?? this.storageLocation,
      isFavorite: isFavorite ?? this.isFavorite,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringIntervalDays: recurringIntervalDays ?? this.recurringIntervalDays,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      barcode: barcode ?? this.barcode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          purchaseDate == other.purchaseDate &&
          expiryDate == other.expiryDate &&
          remainingQuantity == other.remainingQuantity &&
          unit == other.unit &&
          notes == other.notes &&
          imagePath == other.imagePath &&
          isConsumed == other.isConsumed &&
          minimumStock == other.minimumStock &&
          price == other.price &&
          storageLocation == other.storageLocation &&
          isFavorite == other.isFavorite &&
          isRecurring == other.isRecurring &&
          recurringIntervalDays == other.recurringIntervalDays &&
          nextReminderDate == other.nextReminderDate &&
          barcode == other.barcode;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      category.hashCode ^
      purchaseDate.hashCode ^
      expiryDate.hashCode ^
      remainingQuantity.hashCode ^
      unit.hashCode ^
      notes.hashCode ^
      imagePath.hashCode ^
      isConsumed.hashCode ^
      minimumStock.hashCode ^
      price.hashCode ^
      storageLocation.hashCode ^
      isFavorite.hashCode ^
      isRecurring.hashCode ^
      recurringIntervalDays.hashCode ^
      nextReminderDate.hashCode ^
      barcode.hashCode;
}

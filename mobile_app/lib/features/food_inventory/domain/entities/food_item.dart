import '../../../../core/utils/expiry_calculator.dart';
import 'food_category.dart';
import 'food_status.dart';
import 'food_unit.dart';
import 'storage_location.dart';

/// Core domain entity representing an inventory item (groceries, medicines, personal care, or non-expiring products)
class FoodItem {
  final String id;
  final String name;
  final String? brand;
  final String? barcode;
  final FoodCategory category;
  final String? subcategory;
  final DateTime purchaseDate;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final DateTime? reminderDate;
  final bool reminderEnabled;
  final List<int> reminderDaysBefore;
  final int? notificationId;
  final String? expiryStatus;
  final DateTime? lastNotificationSent;
  final double remainingQuantity;
  final FoodUnit unit;
  final String? notes;
  final String? imagePath;
  final bool isConsumed;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional Features
  final double? minimumStock;
  final double? price;
  final StorageLocation storageLocation;
  final bool isFavorite;
  final bool isRecurring;
  final int? recurringIntervalDays;
  final DateTime? nextReminderDate;

  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.category,
    this.subcategory,
    required this.purchaseDate,
    this.manufacturingDate,
    this.expiryDate,
    this.reminderDate,
    this.reminderEnabled = true,
    this.reminderDaysBefore = const [7],
    this.notificationId,
    this.expiryStatus,
    this.lastNotificationSent,
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
  });

  /// Computes active FoodStatus based on expiration status logic (Section 4):
  /// - If no expiry date: No Expiry Date
  /// - If today > expiry date: Expired
  /// - If expiry date is within selected reminder period: Expiring Soon
  /// - Otherwise: Safe
  FoodStatus getStatus({int? warningDays, DateTime? referenceDate}) {
    if (isConsumed || remainingQuantity <= 0) {
      return FoodStatus.consumed;
    }
    if (expiryDate == null) {
      return FoodStatus.noExpiry;
    }
    final days = daysUntilExpiry(referenceDate: referenceDate);
    if (days < 0) {
      return FoodStatus.expired;
    }

    final threshold = warningDays ??
        (reminderDaysBefore.isNotEmpty
            ? reminderDaysBefore.reduce((a, b) => a > b ? a : b)
            : 7);

    if (days <= threshold) {
      return FoodStatus.expiringSoon;
    }
    return FoodStatus.safe;
  }

  /// Whether current active quantity is at or below minimum stock threshold
  bool isLowStock() {
    if (isConsumed || minimumStock == null || minimumStock! <= 0) return false;
    return remainingQuantity <= minimumStock!;
  }

  int daysUntilExpiry({DateTime? referenceDate}) {
    if (expiryDate == null) return 999999;
    return ExpiryCalculator.daysRemaining(expiryDate!, referenceDate: referenceDate);
  }

  int daysRemaining({DateTime? referenceDate}) => daysUntilExpiry(referenceDate: referenceDate);

  int daysStored({DateTime? referenceDate}) {
    return ExpiryCalculator.daysStored(purchaseDate, referenceDate: referenceDate);
  }

  bool isExpired({DateTime? referenceDate}) {
    if (expiryDate == null) return false;
    return daysUntilExpiry(referenceDate: referenceDate) < 0;
  }

  bool isExpiringSoon({int? warningDays, DateTime? referenceDate}) {
    if (expiryDate == null) return false;
    final days = daysUntilExpiry(referenceDate: referenceDate);
    final threshold = warningDays ??
        (reminderDaysBefore.isNotEmpty
            ? reminderDaysBefore.reduce((a, b) => a > b ? a : b)
            : 7);
    return days >= 0 && days <= threshold;
  }

  double freshnessProgress({DateTime? referenceDate}) {
    if (expiryDate == null) return 0.0;
    return ExpiryCalculator.calculateFreshnessProgress(
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      referenceDate: referenceDate,
    );
  }

  String get remainingTimeText => ExpiryCalculator.formatRemainingTime(expiryDate);

  FoodItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? barcode,
    FoodCategory? category,
    String? subcategory,
    DateTime? purchaseDate,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    DateTime? reminderDate,
    bool? reminderEnabled,
    List<int>? reminderDaysBefore,
    int? notificationId,
    String? expiryStatus,
    DateTime? lastNotificationSent,
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
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      reminderDate: reminderDate ?? this.reminderDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notificationId: notificationId ?? this.notificationId,
      expiryStatus: expiryStatus ?? this.expiryStatus,
      lastNotificationSent: lastNotificationSent ?? this.lastNotificationSent,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          brand == other.brand &&
          barcode == other.barcode &&
          category == other.category &&
          subcategory == other.subcategory &&
          purchaseDate == other.purchaseDate &&
          manufacturingDate == other.manufacturingDate &&
          expiryDate == other.expiryDate &&
          reminderDate == other.reminderDate &&
          reminderEnabled == other.reminderEnabled &&
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
          nextReminderDate == other.nextReminderDate;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      (brand?.hashCode ?? 0) ^
      (barcode?.hashCode ?? 0) ^
      category.hashCode ^
      (subcategory?.hashCode ?? 0) ^
      purchaseDate.hashCode ^
      (manufacturingDate?.hashCode ?? 0) ^
      (expiryDate?.hashCode ?? 0) ^
      (reminderDate?.hashCode ?? 0) ^
      reminderEnabled.hashCode ^
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
      nextReminderDate.hashCode;
}

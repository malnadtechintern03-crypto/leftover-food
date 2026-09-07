import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/product_reminder.dart';
import '../../domain/entities/storage_location.dart';
import '../../domain/usecases/add_food_item_usecase.dart';
import '../../domain/usecases/update_food_item_usecase.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import 'food_inventory_providers.dart';
import 'food_list_controller.dart';
import 'food_stats_controller.dart';

class FoodFormState {
  final String? initialId;
  final String name;
  final String? brand;
  final FoodCategory category;
  final String? subcategory;
  final DateTime purchaseDate;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final double quantity;
  final FoodUnit unit;
  final String? notes;
  final String? imagePath;
  final bool isSubmitting;
  final String? errorMessage;

  final StorageLocation storageLocation;
  final double? minimumStock;
  final double? price;
  final bool isFavorite;
  final bool isRecurring;
  final int? recurringIntervalDays;
  final DateTime? nextReminderDate;
  final String? barcode;

  // Reminder settings
  final bool reminderEnabled;
  final List<int> reminderDaysBefore;
  final DateTime? customReminderDate;

  const FoodFormState({
    this.initialId,
    this.name = '',
    this.brand,
    this.category = FoodCategory.grainsAndPulses,
    this.subcategory,
    required this.purchaseDate,
    this.manufacturingDate,
    this.expiryDate,
    this.quantity = 1.0,
    this.unit = FoodUnit.kg,
    this.notes,
    this.imagePath,
    this.isSubmitting = false,
    this.errorMessage,
    this.storageLocation = StorageLocation.pantry,
    this.minimumStock,
    this.price,
    this.isFavorite = false,
    this.isRecurring = false,
    this.recurringIntervalDays,
    this.nextReminderDate,
    this.barcode,
    this.reminderEnabled = true,
    this.reminderDaysBefore = const [3],
    this.customReminderDate,
  });

  bool get isEditing => initialId != null;

  FoodFormState copyWith({
    String? initialId,
    String? name,
    String? brand,
    bool clearBrand = false,
    FoodCategory? category,
    String? subcategory,
    bool clearSubcategory = false,
    DateTime? purchaseDate,
    DateTime? manufacturingDate,
    bool clearManufacturingDate = false,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    double? quantity,
    FoodUnit? unit,
    String? notes,
    bool clearNotes = false,
    String? imagePath,
    bool clearImage = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    StorageLocation? storageLocation,
    double? minimumStock,
    bool clearMinimumStock = false,
    double? price,
    bool clearPrice = false,
    bool? isFavorite,
    bool? isRecurring,
    int? recurringIntervalDays,
    DateTime? nextReminderDate,
    String? barcode,
    bool clearBarcode = false,
    bool? reminderEnabled,
    List<int>? reminderDaysBefore,
    DateTime? customReminderDate,
    bool clearCustomReminderDate = false,
  }) {
    return FoodFormState(
      initialId: initialId ?? this.initialId,
      name: name ?? this.name,
      brand: clearBrand ? null : (brand ?? this.brand),
      category: category ?? this.category,
      subcategory: clearSubcategory ? null : (subcategory ?? this.subcategory),
      purchaseDate: purchaseDate ?? this.purchaseDate,
      manufacturingDate: clearManufacturingDate
          ? null
          : (manufacturingDate ?? this.manufacturingDate),
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      notes: clearNotes ? null : (notes ?? this.notes),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      storageLocation: storageLocation ?? this.storageLocation,
      minimumStock:
          clearMinimumStock ? null : (minimumStock ?? this.minimumStock),
      price: clearPrice ? null : (price ?? this.price),
      isFavorite: isFavorite ?? this.isFavorite,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringIntervalDays:
          recurringIntervalDays ?? this.recurringIntervalDays,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      customReminderDate: clearCustomReminderDate
          ? null
          : (customReminderDate ?? this.customReminderDate),
    );
  }
}

class FoodFormController extends StateNotifier<FoodFormState> {
  final AddFoodItemUseCase _addUseCase;
  final UpdateFoodItemUseCase _updateUseCase;
  final Ref _ref;
  final ImagePicker _imagePicker = ImagePicker();

  FoodFormController(
    this._addUseCase,
    this._updateUseCase,
    this._ref,
    FoodItem? initialItem,
  ) : super(_createInitialState(initialItem));

  static FoodFormState _createInitialState(FoodItem? item) {
    final now = DateTime.now();
    if (item != null) {
      return FoodFormState(
        initialId: item.id,
        name: item.name,
        brand: item.brand,
        category: item.category,
        subcategory: item.subcategory,
        purchaseDate: item.purchaseDate,
        manufacturingDate: item.manufacturingDate,
        expiryDate: item.expiryDate,
        quantity: item.remainingQuantity,
        unit: item.unit,
        notes: item.notes,
        imagePath: item.imagePath,
        storageLocation: item.storageLocation,
        minimumStock: item.minimumStock,
        price: item.price,
        isFavorite: item.isFavorite,
        isRecurring: item.isRecurring,
        recurringIntervalDays: item.recurringIntervalDays,
        nextReminderDate: item.nextReminderDate,
        barcode: item.barcode,
        reminderEnabled: item.reminderEnabled,
        reminderDaysBefore: item.reminderDaysBefore.isNotEmpty
            ? item.reminderDaysBefore
            : const [3],
        customReminderDate: item.reminderDate,
      );
    }
    return FoodFormState(
      purchaseDate: now,
      expiryDate: now.add(const Duration(days: 7)),
      reminderDaysBefore: const [3],
    );
  }

  void setName(String name) {
    state = state.copyWith(name: name, clearError: true);
  }

  void setBrand(String? brand) {
    state = state.copyWith(
      brand: brand,
      clearBrand: brand == null || brand.trim().isEmpty,
      clearError: true,
    );
  }

  void setCategory(FoodCategory category) {
    state = state.copyWith(category: category, clearError: true);
  }

  void setSubcategory(String? subcategory) {
    state = state.copyWith(
      subcategory: subcategory,
      clearSubcategory: subcategory == null || subcategory.trim().isEmpty,
      clearError: true,
    );
  }

  void setStorageLocation(StorageLocation location) {
    state = state.copyWith(storageLocation: location, clearError: true);
  }

  void setPurchaseDate(DateTime date) {
    state = state.copyWith(purchaseDate: date, clearError: true);
  }

  void setManufacturingDate(DateTime? date) {
    state = state.copyWith(
      manufacturingDate: date,
      clearManufacturingDate: date == null,
      clearError: true,
    );
  }

  void setExpiryDate(DateTime? date) {
    state = state.copyWith(
      expiryDate: date,
      clearExpiryDate: date == null,
      clearError: true,
    );
  }

  void clearExpiryDate() {
    state = state.copyWith(clearExpiryDate: true, clearError: true);
  }

  void setQuantity(double quantity) {
    if (quantity > 0) {
      state = state.copyWith(quantity: quantity, clearError: true);
    }
  }

  void setUnit(FoodUnit unit) {
    state = state.copyWith(unit: unit, clearError: true);
  }

  void setMinimumStock(double? minStock) {
    state = state.copyWith(minimumStock: minStock, clearError: true);
  }

  void setPrice(double? price) {
    state = state.copyWith(price: price, clearError: true);
  }

  void toggleFavorite() {
    state = state.copyWith(isFavorite: !state.isFavorite);
  }

  void setIsRecurring(bool recurring, {int intervalDays = 7}) {
    state = state.copyWith(
      isRecurring: recurring,
      recurringIntervalDays: recurring ? intervalDays : null,
      nextReminderDate: recurring ? DateTime.now().add(Duration(days: intervalDays)) : null,
    );
  }

  void setRecurringInterval(int days) {
    state = state.copyWith(
      recurringIntervalDays: days,
      nextReminderDate: DateTime.now().add(Duration(days: days)),
    );
  }

  void setBarcode(String? barcode) {
    state = state.copyWith(barcode: barcode, clearError: true);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes, clearError: true);
  }

  void setReminderEnabled(bool enabled) {
    state = state.copyWith(reminderEnabled: enabled, clearError: true);
  }

  void toggleReminderDay(int days) {
    final list = List<int>.from(state.reminderDaysBefore);
    if (list.contains(days)) {
      list.remove(days);
    } else {
      list.add(days);
      list.sort();
    }
    state = state.copyWith(reminderDaysBefore: list, clearError: true);
  }

  void setReminderDaysBefore(List<int> days) {
    final sorted = List<int>.from(days)..sort();
    state = state.copyWith(reminderDaysBefore: sorted, clearError: true);
  }

  void setCustomReminderDate(DateTime? date) {
    state = state.copyWith(
      customReminderDate: date,
      clearCustomReminderDate: date == null,
      clearError: true,
    );
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        state = state.copyWith(imagePath: picked.path, clearError: true);
      }
    } catch (e) {
      debugPrint('Image pick warning: $e');
    }
  }

  void setImagePath(String? path) {
    if (path == null || path.isEmpty) {
      state = state.copyWith(clearImage: true, clearError: true);
    } else {
      state = state.copyWith(imagePath: path, clearError: true);
    }
  }

  void removeImage() {
    state = state.copyWith(clearImage: true);
  }

  Future<bool> submit() async {
    if (state.name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a product name.');
      return false;
    }

    if (state.expiryDate != null) {
      final purchaseDay = DateTime(
        state.purchaseDate.year,
        state.purchaseDate.month,
        state.purchaseDate.day,
      );
      final expiryDay = DateTime(
        state.expiryDate!.year,
        state.expiryDate!.month,
        state.expiryDate!.day,
      );

      if (expiryDay.isBefore(purchaseDay)) {
        state = state.copyWith(
          errorMessage: 'Expiration date cannot be earlier than purchase date.',
        );
        return false;
      }

      if (state.manufacturingDate != null) {
        final mfgDay = DateTime(
          state.manufacturingDate!.year,
          state.manufacturingDate!.month,
          state.manufacturingDate!.day,
        );
        if (expiryDay.isBefore(mfgDay)) {
          state = state.copyWith(
            errorMessage: 'Expiration date cannot be earlier than manufacturing date.',
          );
          return false;
        }
      }
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final now = DateTime.now();
      final itemId = state.isEditing ? state.initialId! : const Uuid().v4();

      final item = FoodItem(
        id: itemId,
        name: state.name.trim(),
        brand: state.brand?.trim().isEmpty == true ? null : state.brand?.trim(),
        category: state.category,
        subcategory: state.subcategory?.trim().isEmpty == true ? null : state.subcategory?.trim(),
        purchaseDate: state.purchaseDate,
        manufacturingDate: state.manufacturingDate,
        expiryDate: state.expiryDate,
        remainingQuantity: state.quantity,
        unit: state.unit,
        notes: state.notes?.trim().isEmpty == true ? null : state.notes?.trim(),
        imagePath: state.imagePath,
        storageLocation: state.storageLocation,
        minimumStock: state.minimumStock,
        price: state.price,
        isFavorite: state.isFavorite,
        isRecurring: state.isRecurring,
        recurringIntervalDays: state.recurringIntervalDays,
        nextReminderDate: state.nextReminderDate,
        barcode: state.barcode,
        reminderDate: state.customReminderDate,
        reminderEnabled: state.reminderEnabled,
        reminderDaysBefore: state.reminderDaysBefore,
        createdAt: now,
        updatedAt: now,
      );

      if (state.isEditing) {
        await _updateUseCase(item);
      } else {
        await _addUseCase(item);
      }

      // Manage Reminders table and Local Notifications
      final repo = _ref.read(foodRepositoryProvider);
      final settings = _ref.read(settingsControllerProvider).valueOrNull;

      if (state.expiryDate != null && state.reminderEnabled) {
        final remindersList = <ProductReminder>[];
        for (final days in state.reminderDaysBefore) {
          final remDate = DateTime(
            state.expiryDate!.year,
            state.expiryDate!.month,
            state.expiryDate!.day - days,
            settings?.reminderHour ?? 9,
            settings?.reminderMinute ?? 0,
          );
          remindersList.add(ProductReminder(
            id: const Uuid().v4(),
            productId: itemId,
            reminderDate: remDate,
            daysBeforeExpiry: days,
            notificationId: NotificationService.instance.getNotificationId(itemId, days),
            createdAt: now,
            updatedAt: now,
          ));
        }

        if (state.customReminderDate != null) {
          remindersList.add(ProductReminder(
            id: const Uuid().v4(),
            productId: itemId,
            reminderDate: state.customReminderDate!,
            daysBeforeExpiry: 0,
            notificationId: NotificationService.instance.getNotificationId(itemId, 999),
            createdAt: now,
            updatedAt: now,
          ));
        }

        await repo.saveReminders(itemId, remindersList);

        if (settings?.notificationsEnabled != false) {
          await NotificationService.instance.scheduleProductReminders(
            item: item,
            reminderDaysBefore: state.reminderDaysBefore,
            customReminderDate: state.customReminderDate,
            reminderHour: settings?.reminderHour ?? 9,
            reminderMinute: settings?.reminderMinute ?? 0,
            soundEnabled: settings?.soundEnabled ?? true,
            vibrationEnabled: settings?.vibrationEnabled ?? true,
          );
        }
      } else {
        await repo.deleteRemindersForProduct(itemId);
        await NotificationService.instance.cancelProductReminders(itemId);
      }

      _ref.read(foodListControllerProvider.notifier).loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final foodFormControllerProvider = StateNotifierProvider.autoDispose
    .family<FoodFormController, FoodFormState, FoodItem?>((ref, initialItem) {
  final addUseCase = ref.watch(addFoodItemUseCaseProvider);
  final updateUseCase = ref.watch(updateFoodItemUseCaseProvider);

  return FoodFormController(
    addUseCase,
    updateUseCase,
    ref,
    initialItem,
  );
});


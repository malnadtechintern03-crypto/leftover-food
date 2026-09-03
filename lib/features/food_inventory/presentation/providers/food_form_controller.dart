import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_unit.dart';
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
  final FoodCategory category;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final double quantity;
  final FoodUnit unit;
  final String? notes;
  final String? imagePath;
  final bool isSubmitting;
  final String? errorMessage;

  // New attributes
  final StorageLocation storageLocation;
  final double? minimumStock;
  final double? price;
  final bool isFavorite;
  final bool isRecurring;
  final int? recurringIntervalDays;
  final DateTime? nextReminderDate;
  final String? barcode;

  const FoodFormState({
    this.initialId,
    this.name = '',
    this.category = FoodCategory.grainsAndPulses,
    required this.purchaseDate,
    required this.expiryDate,
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
  });

  bool get isEditing => initialId != null;

  FoodFormState copyWith({
    String? initialId,
    String? name,
    FoodCategory? category,
    DateTime? purchaseDate,
    DateTime? expiryDate,
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
  }) {
    return FoodFormState(
      initialId: initialId ?? this.initialId,
      name: name ?? this.name,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      notes: clearNotes ? null : (notes ?? this.notes),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      storageLocation: storageLocation ?? this.storageLocation,
      minimumStock: clearMinimumStock ? null : (minimumStock ?? this.minimumStock),
      price: clearPrice ? null : (price ?? this.price),
      isFavorite: isFavorite ?? this.isFavorite,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringIntervalDays: recurringIntervalDays ?? this.recurringIntervalDays,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
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
        category: item.category,
        purchaseDate: item.purchaseDate,
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
      );
    }
    return FoodFormState(
      purchaseDate: now,
      expiryDate: now.add(const Duration(days: 3)),
    );
  }

  void setName(String name) {
    state = state.copyWith(name: name, clearError: true);
  }

  void setCategory(FoodCategory category) {
    state = state.copyWith(category: category, clearError: true);
  }

  void setStorageLocation(StorageLocation location) {
    state = state.copyWith(storageLocation: location, clearError: true);
  }

  void setPurchaseDate(DateTime date) {
    state = state.copyWith(purchaseDate: date, clearError: true);
  }

  void setExpiryDate(DateTime date) {
    state = state.copyWith(expiryDate: date, clearError: true);
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
      state = state.copyWith(errorMessage: 'Please enter a grocery item name.');
      return false;
    }

    if (state.expiryDate.isBefore(
      DateTime(
        state.purchaseDate.year,
        state.purchaseDate.month,
        state.purchaseDate.day,
      ),
    )) {
      state = state.copyWith(
        errorMessage: 'Expiry date cannot be earlier than purchase date.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final now = DateTime.now();
      if (state.isEditing) {
        final existingId = state.initialId!;
        final updatedItem = FoodItem(
          id: existingId,
          name: state.name.trim(),
          category: state.category,
          purchaseDate: state.purchaseDate,
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
          createdAt: now,
          updatedAt: now,
        );
        await _updateUseCase(updatedItem);
      } else {
        final newItem = FoodItem(
          id: const Uuid().v4(),
          name: state.name.trim(),
          category: state.category,
          purchaseDate: state.purchaseDate,
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
          createdAt: now,
          updatedAt: now,
        );
        await _addUseCase(newItem);

        // Schedule local alert reminder if notifications are enabled
        final settings = _ref.read(settingsControllerProvider).valueOrNull;
        if (settings?.notificationsEnabled == true) {
          final daysLeft = newItem.daysUntilExpiry();
          if (daysLeft <= (settings?.expiryWarningDays ?? 2)) {
            await NotificationService.instance.showExpiryAlert(
              id: newItem.id.hashCode,
              title: 'Grocery Alert: ${newItem.name}',
              body: 'Expires in $daysLeft day(s). Remember to use it!',
            );
          }
        }
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

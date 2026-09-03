import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_filter.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_status.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/storage_location.dart';
import '../../domain/usecases/consume_food_item_usecase.dart';
import '../../domain/usecases/delete_food_item_usecase.dart';
import '../../domain/usecases/get_food_items_usecase.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import 'food_inventory_providers.dart';
import 'food_stats_controller.dart';

/// State for the food inventory list
class FoodListState {
  final AsyncValue<List<FoodItem>> items;
  final FoodFilter filter;
  final int warningDays;

  const FoodListState({
    required this.items,
    this.filter = const FoodFilter(),
    this.warningDays = 2,
  });

  FoodListState copyWith({
    AsyncValue<List<FoodItem>>? items,
    FoodFilter? filter,
    int? warningDays,
  }) {
    return FoodListState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      warningDays: warningDays ?? this.warningDays,
    );
  }
}

class FoodListController extends StateNotifier<FoodListState> {
  final GetFoodItemsUseCase _getItemsUseCase;
  final DeleteFoodItemUseCase _deleteUseCase;
  final ConsumeFoodItemUseCase _consumeUseCase;
  final Ref _ref;

  FoodListController(
    this._getItemsUseCase,
    this._deleteUseCase,
    this._consumeUseCase,
    this._ref,
    int initialWarningDays,
  ) : super(FoodListState(
          items: const AsyncValue.loading(),
          warningDays: initialWarningDays,
        )) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = state.copyWith(items: const AsyncValue.loading());
    try {
      final items = await _getItemsUseCase(
        filter: state.filter,
        warningDays: state.warningDays,
      );
      if (!mounted) return;
      state = state.copyWith(items: AsyncValue.data(items));
    } catch (e, stack) {
      if (!mounted) return;
      state = state.copyWith(items: AsyncValue.error(e, stack));
    }
  }

  void updateWarningDays(int days) {
    if (state.warningDays != days) {
      state = state.copyWith(warningDays: days);
      loadItems();
    }
  }

  void setSearchQuery(String query) {
    final updatedFilter = state.filter.copyWith(searchQuery: query);
    state = state.copyWith(filter: updatedFilter);
    loadItems();
  }

  void setCategory(FoodCategory? category) {
    FoodFilter updatedFilter;
    if (category == null || state.filter.category == category) {
      updatedFilter = state.filter.copyWith(clearCategory: true);
    } else {
      updatedFilter = state.filter.copyWith(category: category);
    }
    state = state.copyWith(filter: updatedFilter);
    loadItems();
  }

  void setStorageLocation(StorageLocation? location) {
    FoodFilter updatedFilter;
    if (location == null || state.filter.storageLocation == location) {
      updatedFilter = state.filter.copyWith(clearStorageLocation: true);
    } else {
      updatedFilter = state.filter.copyWith(storageLocation: location);
    }
    state = state.copyWith(filter: updatedFilter);
    loadItems();
  }

  void setStatus(FoodStatus? status) {
    FoodFilter updatedFilter;
    if (status == null || state.filter.status == status) {
      updatedFilter = state.filter.copyWith(clearStatus: true);
    } else {
      updatedFilter = state.filter.copyWith(status: status);
    }
    state = state.copyWith(filter: updatedFilter);
    loadItems();
  }

  void setFavoriteOnly(bool? isFavorite) {
    FoodFilter updatedFilter;
    if (isFavorite == null || state.filter.isFavorite == isFavorite) {
      updatedFilter = state.filter.copyWith(clearIsFavorite: true);
    } else {
      updatedFilter = state.filter.copyWith(isFavorite: isFavorite);
    }
    state = state.copyWith(filter: updatedFilter);
    loadItems();
  }

  void setLowStockOnly(bool? isLowStock) {
    FoodFilter updatedFilter;
    if (isLowStock == null || state.filter.isLowStock == isLowStock) {
      updatedFilter = state.filter.copyWith(clearIsLowStock: true);
    } else {
      updatedFilter = state.filter.copyWith(isLowStock: isLowStock);
    }
    state = state.copyWith(filter: updatedFilter);
    loadItems();
  }

  void setSortOption(FoodSortOption sortOption) {
    final updatedFilter = state.filter.copyWith(sortOption: sortOption);
    state = state.copyWith(filter: updatedFilter);
    loadItems();
  }

  void toggleIncludeConsumed(bool include) {
    final updatedFilter = state.filter.copyWith(includeConsumed: include);
    state = state.copyWith(filter: updatedFilter);
    loadItems();
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final repo = _ref.read(foodRepositoryProvider);
      await repo.toggleFavorite(id);
      await loadItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> quickAddFood({
    required String name,
    required double quantity,
    required DateTime expiryDate,
    FoodCategory category = FoodCategory.other,
    FoodUnit unit = FoodUnit.pieces,
    StorageLocation location = StorageLocation.pantry,
    double? price,
    double? minStock,
    String? barcode,
  }) async {
    try {
      final now = DateTime.now();
      final newItem = FoodItem(
        id: const Uuid().v4(),
        name: name.trim(),
        category: category,
        purchaseDate: now,
        expiryDate: expiryDate,
        remainingQuantity: quantity,
        unit: unit,
        storageLocation: location,
        price: price,
        minimumStock: minStock,
        barcode: barcode,
        createdAt: now,
        updatedAt: now,
      );
      final repo = _ref.read(foodRepositoryProvider);
      await repo.addFoodItem(newItem);
      await loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFood(String id) async {
    try {
      await _deleteUseCase(id);
      await loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> consumeFood(String id, double quantity) async {
    try {
      await _consumeUseCase(id, quantity);
      await loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearConsumedItems() async {
    try {
      final repo = _ref.read(foodRepositoryProvider);
      final consumedItems = await repo.getFoodItems(
        filter: const FoodFilter(includeConsumed: true, status: FoodStatus.consumed),
      );
      for (final item in consumedItems) {
        await repo.deleteFoodItem(item.id);
      }
      await loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetDemoData() async {
    try {
      final repo = _ref.read(foodRepositoryProvider);
      await repo.clearAllData();
      await repo.seedInitialData();
      await loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      final repo = _ref.read(foodRepositoryProvider);
      await repo.clearAllData();
      await loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();
    } catch (e) {
      rethrow;
    }
  }
}

final foodListControllerProvider =
    StateNotifierProvider<FoodListController, FoodListState>((ref) {
  final getItems = ref.watch(getFoodItemsUseCaseProvider);
  final deleteItem = ref.watch(deleteFoodItemUseCaseProvider);
  final consumeItem = ref.watch(consumeFoodItemUseCaseProvider);
  final warningDays = ref.watch(
    settingsControllerProvider.select((s) => s.valueOrNull?.expiryWarningDays ?? 2),
  );

  return FoodListController(
    getItems,
    deleteItem,
    consumeItem,
    ref,
    warningDays,
  );
});

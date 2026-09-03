import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../food_inventory/domain/entities/food_category.dart';
import '../../../food_inventory/domain/entities/food_unit.dart';
import '../../../food_inventory/domain/entities/storage_location.dart';
import '../../../food_inventory/presentation/providers/food_list_controller.dart';
import '../../data/datasources/shopping_local_datasource.dart';
import '../../data/repositories/shopping_repository_impl.dart';
import '../../domain/entities/shopping_item.dart';
import '../../domain/repositories/shopping_repository.dart';

final shoppingLocalDataSourceProvider = Provider<ShoppingLocalDataSource>((ref) {
  return ShoppingLocalDataSourceImpl(DatabaseHelper.instance);
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  final ds = ref.watch(shoppingLocalDataSourceProvider);
  return ShoppingRepositoryImpl(ds);
});

class ShoppingListState {
  final AsyncValue<List<ShoppingItem>> items;
  final String searchQuery;
  final bool? filterPurchased;
  final ShoppingPriority? filterPriority;

  const ShoppingListState({
    required this.items,
    this.searchQuery = '',
    this.filterPurchased,
    this.filterPriority,
  });

  ShoppingListState copyWith({
    AsyncValue<List<ShoppingItem>>? items,
    String? searchQuery,
    bool? filterPurchased,
    bool clearFilterPurchased = false,
    ShoppingPriority? filterPriority,
    bool clearFilterPriority = false,
  }) {
    return ShoppingListState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      filterPurchased: clearFilterPurchased ? null : (filterPurchased ?? this.filterPurchased),
      filterPriority: clearFilterPriority ? null : (filterPriority ?? this.filterPriority),
    );
  }
}

class ShoppingListController extends StateNotifier<ShoppingListState> {
  final ShoppingRepository _repository;
  final Ref _ref;

  ShoppingListController(this._repository, this._ref)
      : super(const ShoppingListState(items: AsyncValue.loading())) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = state.copyWith(items: const AsyncValue.loading());
    try {
      final items = await _repository.getShoppingItems(
        searchQuery: state.searchQuery,
        isPurchased: state.filterPurchased,
      );
      if (!mounted) return;
      var filtered = items;
      if (state.filterPriority != null) {
        filtered = filtered.where((i) => i.priority == state.filterPriority).toList();
      }
      state = state.copyWith(items: AsyncValue.data(filtered));
    } catch (e, stack) {
      if (!mounted) return;
      state = state.copyWith(items: AsyncValue.error(e, stack));
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadItems();
  }

  void setFilterPurchased(bool? purchased) {
    if (state.filterPurchased == purchased) {
      state = state.copyWith(clearFilterPurchased: true);
    } else {
      state = state.copyWith(filterPurchased: purchased);
    }
    loadItems();
  }

  void setFilterPriority(ShoppingPriority? priority) {
    if (state.filterPriority == priority) {
      state = state.copyWith(clearFilterPriority: true);
    } else {
      state = state.copyWith(filterPriority: priority);
    }
    loadItems();
  }

  Future<void> addItem({
    required String name,
    required double quantity,
    required FoodUnit unit,
    FoodCategory category = FoodCategory.other,
    ShoppingPriority priority = ShoppingPriority.medium,
  }) async {
    final now = DateTime.now();
    final item = ShoppingItem(
      id: const Uuid().v4(),
      name: name.trim(),
      quantity: quantity,
      unit: unit,
      category: category,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.addShoppingItem(item);
    await loadItems();
  }

  Future<void> updateItem(ShoppingItem item) async {
    await _repository.updateShoppingItem(item);
    await loadItems();
  }

  Future<void> togglePurchased(String id) async {
    await _repository.togglePurchased(id);
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _repository.deleteShoppingItem(id);
    await loadItems();
  }

  Future<void> clearPurchased() async {
    await _repository.clearPurchasedItems();
    await loadItems();
  }

  /// Converts a purchased shopping item into an active pantry grocery item
  Future<void> addToPantry({
    required ShoppingItem shoppingItem,
    required DateTime expiryDate,
    StorageLocation location = StorageLocation.pantry,
    double? price,
  }) async {
    await _ref.read(foodListControllerProvider.notifier).quickAddFood(
          name: shoppingItem.name,
          quantity: shoppingItem.quantity,
          expiryDate: expiryDate,
          category: shoppingItem.category,
          unit: shoppingItem.unit,
          location: location,
          price: price,
        );
    await _repository.deleteShoppingItem(shoppingItem.id);
    await loadItems();
  }
}

final shoppingListControllerProvider =
    StateNotifierProvider<ShoppingListController, ShoppingListState>((ref) {
  final repo = ref.watch(shoppingRepositoryProvider);
  return ShoppingListController(repo, ref);
});

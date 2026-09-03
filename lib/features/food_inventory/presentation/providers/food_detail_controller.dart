import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/usecases/consume_food_item_usecase.dart';
import '../../domain/usecases/delete_food_item_usecase.dart';
import '../../domain/usecases/get_food_item_by_id_usecase.dart';
import '../../domain/usecases/update_food_item_usecase.dart';
import 'food_inventory_providers.dart';
import 'food_list_controller.dart';
import 'food_stats_controller.dart';

class FoodDetailController extends StateNotifier<AsyncValue<FoodItem?>> {
  final String id;
  final GetFoodItemByIdUseCase _getByIdUseCase;
  final UpdateFoodItemUseCase _updateUseCase;
  final DeleteFoodItemUseCase _deleteUseCase;
  final ConsumeFoodItemUseCase _consumeUseCase;
  final Ref _ref;

  FoodDetailController(
    this.id,
    this._getByIdUseCase,
    this._updateUseCase,
    this._deleteUseCase,
    this._consumeUseCase,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    loadItem();
  }

  Future<void> loadItem() async {
    state = const AsyncValue.loading();
    try {
      final item = await _getByIdUseCase(id);
      state = AsyncValue.data(item);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> consume(double quantity) async {
    try {
      await _consumeUseCase(id, quantity);
      await loadItem();
      _ref.read(foodListControllerProvider.notifier).loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> extendExpiry(DateTime newExpiryDate) async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      final updated = current.copyWith(
        expiryDate: newExpiryDate,
        updatedAt: DateTime.now(),
      );
      await _updateUseCase(updated);
      await loadItem();
      _ref.read(foodListControllerProvider.notifier).loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete() async {
    try {
      await _deleteUseCase(id);
      _ref.read(foodListControllerProvider.notifier).loadItems();
      _ref.read(foodStatsControllerProvider.notifier).loadStats();
    } catch (e) {
      rethrow;
    }
  }
}

final foodDetailControllerProvider = StateNotifierProvider.family<
    FoodDetailController, AsyncValue<FoodItem?>, String>((ref, id) {
  final getById = ref.watch(getFoodItemByIdUseCaseProvider);
  final updateItem = ref.watch(updateFoodItemUseCaseProvider);
  final deleteItem = ref.watch(deleteFoodItemUseCaseProvider);
  final consumeItem = ref.watch(consumeFoodItemUseCaseProvider);

  return FoodDetailController(
    id,
    getById,
    updateItem,
    deleteItem,
    consumeItem,
    ref,
  );
});

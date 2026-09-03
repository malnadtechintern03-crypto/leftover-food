import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/core/errors/failure.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_filter.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_stats.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:foodsave/features/food_inventory/domain/repositories/food_repository.dart';
import 'package:foodsave/features/food_inventory/domain/usecases/add_food_item_usecase.dart';
import 'package:foodsave/features/food_inventory/domain/usecases/consume_food_item_usecase.dart';

class MockFoodRepository implements FoodRepository {
  final List<FoodItem> items = [];

  @override
  Future<void> addFoodItem(FoodItem item) async {
    items.add(item);
  }

  @override
  Future<void> consumeFoodItem(String id, double consumedQuantity) async {
    final idx = items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final item = items[idx];
      final newQty = (item.remainingQuantity - consumedQuantity).clamp(0.0, double.infinity);
      items[idx] = item.copyWith(
        remainingQuantity: newQty,
        isConsumed: newQty <= 0,
      );
    }
  }

  @override
  Future<void> clearAllData() async => items.clear();

  @override
  Future<void> deleteFoodItem(String id) async {
    items.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<FoodItem>> getExpiringFoodItems({int warningDays = 2}) async => [];

  @override
  Future<FoodItem?> getFoodItemById(String id) async {
    return items.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<FoodItem?> getFoodItemByBarcode(String barcode) async {
    return items.where((e) => e.barcode == barcode && !e.isConsumed).firstOrNull;
  }

  @override
  Future<List<FoodItem>> getFoodItems({FoodFilter? filter, int warningDays = 2}) async => items;

  @override
  Future<FoodStats> getFoodStats({int warningDays = 2}) async => const FoodStats();

  @override
  Future<void> seedInitialData() async {}

  @override
  Future<void> toggleFavorite(String id) async {
    final idx = items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(isFavorite: !items[idx].isFavorite);
    }
  }

  @override
  Future<List<FoodItem>> getLowStockItems() async =>
      items.where((e) => e.isLowStock()).toList();

  @override
  Future<List<FoodItem>> getRecurringGroceries() async =>
      items.where((e) => e.isRecurring).toList();

  @override
  Future<void> updateFoodItem(FoodItem item) async {}
}

void main() {
  group('UseCases Validation Tests', () {
    late MockFoodRepository mockRepo;
    late AddFoodItemUseCase addUseCase;
    late ConsumeFoodItemUseCase consumeUseCase;

    setUp(() {
      mockRepo = MockFoodRepository();
      addUseCase = AddFoodItemUseCase(mockRepo);
      consumeUseCase = ConsumeFoodItemUseCase(mockRepo);
    });

    test('AddFoodItemUseCase throws ValidationFailure on empty food name', () async {
      final now = DateTime.now();
      final item = FoodItem(
        id: '1',
        name: '   ',
        category: FoodCategory.grainsAndPulses,
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 2)),
        remainingQuantity: 1,
        unit: FoodUnit.kg,
        createdAt: now,
        updatedAt: now,
      );

      expect(() => addUseCase(item), throwsA(isA<ValidationFailure>()));
    });

    test('AddFoodItemUseCase throws ValidationFailure on non-positive quantity', () async {
      final now = DateTime.now();
      final item = FoodItem(
        id: '2',
        name: 'Basmati Rice',
        category: FoodCategory.grainsAndPulses,
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 2)),
        remainingQuantity: 0,
        unit: FoodUnit.kg,
        createdAt: now,
        updatedAt: now,
      );

      expect(() => addUseCase(item), throwsA(isA<ValidationFailure>()));
    });

    test('AddFoodItemUseCase succeeds for valid food item', () async {
      final now = DateTime.now();
      final item = FoodItem(
        id: '3',
        name: 'Extra Virgin Olive Oil',
        category: FoodCategory.oils,
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 180)),
        remainingQuantity: 2,
        unit: FoodUnit.litre,
        createdAt: now,
        updatedAt: now,
      );

      await addUseCase(item);
      expect(mockRepo.items.length, 1);
      expect(mockRepo.items.first.name, 'Extra Virgin Olive Oil');
    });

    test('ConsumeFoodItemUseCase decrements quantity and marks consumed', () async {
      final now = DateTime.now();
      final item = FoodItem(
        id: '4',
        name: 'Whole Milk',
        category: FoodCategory.dairy,
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 2)),
        remainingQuantity: 2,
        unit: FoodUnit.litre,
        createdAt: now,
        updatedAt: now,
      );
      await addUseCase(item);

      await consumeUseCase('4', 1.0);
      expect(mockRepo.items.first.remainingQuantity, 1.0);
      expect(mockRepo.items.first.isConsumed, false);

      await consumeUseCase('4', 1.0);
      expect(mockRepo.items.first.remainingQuantity, 0.0);
      expect(mockRepo.items.first.isConsumed, true);
    });
  });
}

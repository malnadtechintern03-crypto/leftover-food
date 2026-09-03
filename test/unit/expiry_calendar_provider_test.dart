import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/features/expiry_calendar/presentation/providers/expiry_calendar_provider.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_filter.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_stats.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:foodsave/features/food_inventory/domain/repositories/food_repository.dart';
import 'package:foodsave/features/food_inventory/domain/usecases/get_food_items_usecase.dart';

class MockCalendarFoodRepository implements FoodRepository {
  List<FoodItem> mockItems = [];

  @override
  Future<List<FoodItem>> getFoodItems({FoodFilter? filter, int warningDays = 2}) async {
    return mockItems;
  }

  @override
  Future<FoodItem?> getFoodItemById(String id) async => null;
  @override
  Future<FoodItem?> getFoodItemByBarcode(String barcode) async => null;
  @override
  Future<void> addFoodItem(FoodItem item) async {}
  @override
  Future<void> updateFoodItem(FoodItem item) async {}
  @override
  Future<void> deleteFoodItem(String id) async {}
  @override
  Future<void> consumeFoodItem(String id, double quantity) async {}
  @override
  Future<List<FoodItem>> getExpiringFoodItems({int warningDays = 2}) async => [];
  @override
  Future<void> toggleFavorite(String id) async {}
  @override
  Future<List<FoodItem>> getLowStockItems() async => [];
  @override
  Future<List<FoodItem>> getRecurringGroceries() async => [];
  @override
  Future<FoodStats> getFoodStats({int warningDays = 2}) async => const FoodStats();
  @override
  Future<void> seedInitialData() async {}
  @override
  Future<void> clearAllData() async {}
}

void main() {
  group('ExpiryCalendarProvider & State Tests', () {
    late MockCalendarFoodRepository mockRepo;
    late GetFoodItemsUseCase getItemsUseCase;

    final baseDate = DateTime(2026, 9, 10, 12, 0);
    final item1 = FoodItem(
      id: 'item-1',
      name: 'Whole Milk',
      category: FoodCategory.dairy,
      purchaseDate: baseDate.subtract(const Duration(days: 2)),
      expiryDate: baseDate,
      remainingQuantity: 1,
      unit: FoodUnit.litre,
      createdAt: baseDate,
      updatedAt: baseDate,
    );
    final item2 = FoodItem(
      id: 'item-2',
      name: 'Sourdough Bread',
      category: FoodCategory.flourAndBaking,
      purchaseDate: baseDate.subtract(const Duration(days: 2)),
      expiryDate: baseDate,
      remainingQuantity: 1,
      unit: FoodUnit.pieces,
      createdAt: baseDate,
      updatedAt: baseDate,
    );
    final item3 = FoodItem(
      id: 'item-3',
      name: 'Digestive Biscuits',
      category: FoodCategory.snacksAndPackaged,
      purchaseDate: baseDate.subtract(const Duration(days: 5)),
      expiryDate: baseDate.add(const Duration(days: 5)),
      remainingQuantity: 200,
      unit: FoodUnit.grams,
      createdAt: baseDate,
      updatedAt: baseDate,
    );

    setUp(() {
      mockRepo = MockCalendarFoodRepository();
      mockRepo.mockItems = [item1, item2, item3];
      getItemsUseCase = GetFoodItemsUseCase(mockRepo);
    });

    test('Loads and groups grocery items by expiry date key correctly', () async {
      final controller = ExpiryCalendarController(getItemsUseCase, 2);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = controller.state;
      expect(state.items.hasValue, true);
      expect(state.items.value!.length, 3);

      final dateKey1 = ExpiryCalendarState.dateKey(baseDate);
      expect(state.itemsByDateKey.containsKey(dateKey1), true);
      expect(state.itemsByDateKey[dateKey1]!.length, 2);
      expect(state.itemsByDateKey[dateKey1]!.map((e) => e.name), containsAll(['Whole Milk', 'Sourdough Bread']));

      final dateKey2 = ExpiryCalendarState.dateKey(baseDate.add(const Duration(days: 5)));
      expect(state.itemsByDateKey.containsKey(dateKey2), true);
      expect(state.itemsByDateKey[dateKey2]!.length, 1);
    });

    test('selectDate updates selectedDate and selectedMonth accordingly', () async {
      final controller = ExpiryCalendarController(getItemsUseCase, 2);
      final targetDate = DateTime(2026, 10, 15);

      controller.selectDate(targetDate);
      expect(controller.state.selectedDate.year, 2026);
      expect(controller.state.selectedDate.month, 10);
      expect(controller.state.selectedDate.day, 15);
      expect(controller.state.selectedMonth.month, 10);
    });

    test('nextMonth and previousMonth navigate calendar months smoothly', () async {
      final controller = ExpiryCalendarController(getItemsUseCase, 2);
      controller.selectDate(DateTime(2026, 9, 15));

      controller.nextMonth();
      expect(controller.state.selectedMonth.month, 10);

      controller.previousMonth();
      expect(controller.state.selectedMonth.month, 9);
    });

    test('goToToday resets calendar to current month and day', () async {
      final controller = ExpiryCalendarController(getItemsUseCase, 2);
      controller.selectDate(DateTime(2025, 1, 1));
      expect(controller.state.selectedMonth.year, 2025);

      controller.goToToday();
      final now = DateTime.now();
      expect(controller.state.selectedMonth.year, now.year);
      expect(controller.state.selectedMonth.month, now.month);
      expect(controller.state.selectedDate.day, now.day);
    });

    test('setViewMode toggles between month, week, and day modes', () {
      final controller = ExpiryCalendarController(getItemsUseCase, 2);
      expect(controller.state.viewMode, CalendarViewMode.month);

      controller.setViewMode(CalendarViewMode.week);
      expect(controller.state.viewMode, CalendarViewMode.week);

      controller.setViewMode(CalendarViewMode.day);
      expect(controller.state.viewMode, CalendarViewMode.day);
    });
  });
}

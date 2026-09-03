import '../../domain/entities/food_filter.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_stats.dart';
import '../../domain/repositories/food_repository.dart';
import '../datasources/food_local_datasource.dart';
import '../models/food_item_model.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodLocalDataSource _localDataSource;

  FoodRepositoryImpl(this._localDataSource);

  @override
  Future<List<FoodItem>> getFoodItems({
    FoodFilter? filter,
    int warningDays = 2,
  }) async {
    return await _localDataSource.getFoodItems(
      filter: filter,
      warningDays: warningDays,
    );
  }

  @override
  Future<FoodItem?> getFoodItemById(String id) async {
    return await _localDataSource.getFoodItemById(id);
  }

  @override
  Future<FoodItem?> getFoodItemByBarcode(String barcode) async {
    return await _localDataSource.getFoodItemByBarcode(barcode);
  }

  @override
  Future<void> addFoodItem(FoodItem item) async {
    final model = FoodItemModel.fromEntity(item);
    await _localDataSource.insertFoodItem(model);
  }

  @override
  Future<void> updateFoodItem(FoodItem item) async {
    final model = FoodItemModel.fromEntity(item);
    await _localDataSource.updateFoodItem(model);
  }

  @override
  Future<void> deleteFoodItem(String id) async {
    await _localDataSource.deleteFoodItem(id);
  }

  @override
  Future<void> consumeFoodItem(String id, double consumedQuantity) async {
    await _localDataSource.consumeFoodItem(id, consumedQuantity);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    await _localDataSource.toggleFavorite(id);
  }

  @override
  Future<List<FoodItem>> getExpiringFoodItems({int warningDays = 2}) async {
    return await _localDataSource.getExpiringFoodItems(warningDays: warningDays);
  }

  @override
  Future<List<FoodItem>> getLowStockItems() async {
    return await _localDataSource.getLowStockItems();
  }

  @override
  Future<List<FoodItem>> getRecurringGroceries() async {
    return await _localDataSource.getRecurringGroceries();
  }

  @override
  Future<FoodStats> getFoodStats({int warningDays = 2}) async {
    return await _localDataSource.getFoodStats(warningDays: warningDays);
  }

  @override
  Future<void> seedInitialData() async {
    await _localDataSource.seedSampleData();
  }

  @override
  Future<void> clearAllData() async {
    await _localDataSource.clearAllData();
  }
}

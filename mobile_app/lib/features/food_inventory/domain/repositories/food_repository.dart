import '../entities/food_filter.dart';
import '../entities/food_item.dart';
import '../entities/food_stats.dart';
import '../entities/product_reminder.dart';

/// Repository contract for product and inventory operations
abstract class FoodRepository {
  Future<List<FoodItem>> getFoodItems({
    FoodFilter? filter,
    int warningDays = 2,
  });

  Future<FoodItem?> getFoodItemById(String id);

  Future<FoodItem?> getFoodItemByBarcode(String barcode);

  Future<void> addFoodItem(FoodItem item);

  Future<void> updateFoodItem(FoodItem item);

  Future<void> deleteFoodItem(String id);

  Future<void> consumeFoodItem(String id, double consumedQuantity);

  Future<void> toggleFavorite(String id);

  Future<List<FoodItem>> getExpiringFoodItems({int warningDays = 2});

  Future<List<FoodItem>> getLowStockItems();

  Future<List<FoodItem>> getRecurringGroceries();

  Future<FoodStats> getFoodStats({int warningDays = 2});

  Future<List<ProductReminder>> getRemindersForProduct(String productId);

  Future<void> saveReminders(
    String productId,
    List<ProductReminder> reminders,
  );

  Future<void> deleteRemindersForProduct(String productId);

  Future<void> dismissReminder(String reminderId);

  Future<List<ProductReminder>> getAllActiveReminders();

  Future<void> seedInitialData();

  Future<void> clearAllData();
}


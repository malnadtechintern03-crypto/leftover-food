import '../entities/shopping_item.dart';

abstract class ShoppingRepository {
  Future<List<ShoppingItem>> getShoppingItems({String? searchQuery, bool? isPurchased});
  Future<ShoppingItem?> getShoppingItemById(String id);
  Future<void> addShoppingItem(ShoppingItem item);
  Future<void> updateShoppingItem(ShoppingItem item);
  Future<void> togglePurchased(String id);
  Future<void> deleteShoppingItem(String id);
  Future<void> clearPurchasedItems();
}

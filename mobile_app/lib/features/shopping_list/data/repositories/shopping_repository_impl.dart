import '../../domain/entities/shopping_item.dart';
import '../../domain/repositories/shopping_repository.dart';
import '../datasources/shopping_local_datasource.dart';
import '../models/shopping_item_model.dart';

class ShoppingRepositoryImpl implements ShoppingRepository {
  final ShoppingLocalDataSource _localDataSource;

  ShoppingRepositoryImpl(this._localDataSource);

  @override
  Future<List<ShoppingItem>> getShoppingItems({String? searchQuery, bool? isPurchased}) async {
    return await _localDataSource.getShoppingItems(
      searchQuery: searchQuery,
      isPurchased: isPurchased,
    );
  }

  @override
  Future<ShoppingItem?> getShoppingItemById(String id) async {
    return await _localDataSource.getShoppingItemById(id);
  }

  @override
  Future<void> addShoppingItem(ShoppingItem item) async {
    final model = ShoppingItemModel.fromEntity(item);
    await _localDataSource.insertShoppingItem(model);
  }

  @override
  Future<void> updateShoppingItem(ShoppingItem item) async {
    final model = ShoppingItemModel.fromEntity(item);
    await _localDataSource.updateShoppingItem(model);
  }

  @override
  Future<void> togglePurchased(String id) async {
    await _localDataSource.togglePurchased(id);
  }

  @override
  Future<void> deleteShoppingItem(String id) async {
    await _localDataSource.deleteShoppingItem(id);
  }

  @override
  Future<void> clearPurchasedItems() async {
    await _localDataSource.clearPurchasedItems();
  }
}

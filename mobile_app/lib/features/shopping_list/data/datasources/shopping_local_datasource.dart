import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/shopping_item_model.dart';

abstract class ShoppingLocalDataSource {
  Future<List<ShoppingItemModel>> getShoppingItems({
    String? searchQuery,
    bool? isPurchased,
  });
  Future<ShoppingItemModel?> getShoppingItemById(String id);
  Future<void> insertShoppingItem(ShoppingItemModel item);
  Future<void> updateShoppingItem(ShoppingItemModel item);
  Future<void> togglePurchased(String id);
  Future<void> deleteShoppingItem(String id);
  Future<void> clearPurchasedItems();
}

class ShoppingLocalDataSourceImpl implements ShoppingLocalDataSource {
  final DatabaseHelper _dbHelper;
  static final List<ShoppingItemModel> _memoryStore = [];

  ShoppingLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<ShoppingItemModel>> getShoppingItems({
    String? searchQuery,
    bool? isPurchased,
  }) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        final whereClauses = <String>[];
        final whereArgs = <dynamic>[];

        if (isPurchased != null) {
          whereClauses.add('is_purchased = ?');
          whereArgs.add(isPurchased ? 1 : 0);
        }

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          whereClauses.add('name LIKE ?');
          whereArgs.add('%${searchQuery.trim()}%');
        }

        final whereString =
            whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

        final results = await db.query(
          AppConstants.shoppingTable,
          where: whereString,
          whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
          orderBy: 'is_purchased ASC, created_at DESC',
        );

        return results.map((e) => ShoppingItemModel.fromMap(e)).toList();
      }

      var items = List<ShoppingItemModel>.from(_memoryStore);
      if (isPurchased != null) {
        items = items.where((i) => i.isPurchased == isPurchased).toList();
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        items = items.where((i) => i.name.toLowerCase().contains(q)).toList();
      }
      items.sort((a, b) {
        if (a.isPurchased != b.isPurchased) {
          return a.isPurchased ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return items;
    } catch (e) {
      throw DatabaseException('Failed to get shopping items: $e');
    }
  }

  @override
  Future<ShoppingItemModel?> getShoppingItemById(String id) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        final results = await db.query(
          AppConstants.shoppingTable,
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (results.isEmpty) return null;
        return ShoppingItemModel.fromMap(results.first);
      }
      final idx = _memoryStore.indexWhere((i) => i.id == id);
      return idx != -1 ? _memoryStore[idx] : null;
    } catch (e) {
      throw DatabaseException('Failed to get shopping item with id $id: $e');
    }
  }

  @override
  Future<void> insertShoppingItem(ShoppingItemModel item) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.insert(
          AppConstants.shoppingTable,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final idx = _memoryStore.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        _memoryStore[idx] = item;
      } else {
        _memoryStore.add(item);
      }
    } catch (e) {
      throw DatabaseException('Failed to insert shopping item: $e');
    }
  }

  @override
  Future<void> updateShoppingItem(ShoppingItemModel item) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.update(
          AppConstants.shoppingTable,
          item.toMap(),
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }

      final idx = _memoryStore.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        _memoryStore[idx] = item;
      }
    } catch (e) {
      throw DatabaseException('Failed to update shopping item: $e');
    }
  }

  @override
  Future<void> togglePurchased(String id) async {
    try {
      final item = await getShoppingItemById(id);
      if (item == null) return;
      final newStatus = !item.isPurchased;

      final db = await _dbHelper.database;
      if (db != null) {
        await db.update(
          AppConstants.shoppingTable,
          {
            'is_purchased': newStatus ? 1 : 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      final updated = item.copyWith(isPurchased: newStatus, updatedAt: DateTime.now());
      final idx = _memoryStore.indexWhere((i) => i.id == id);
      if (idx >= 0) {
        _memoryStore[idx] = ShoppingItemModel.fromEntity(updated);
      }
    } catch (e) {
      throw DatabaseException('Failed to toggle shopping item purchase status: $e');
    }
  }

  @override
  Future<void> deleteShoppingItem(String id) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.delete(
          AppConstants.shoppingTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      _memoryStore.removeWhere((i) => i.id == id);
    } catch (e) {
      throw DatabaseException('Failed to delete shopping item: $e');
    }
  }

  @override
  Future<void> clearPurchasedItems() async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.delete(
          AppConstants.shoppingTable,
          where: 'is_purchased = 1',
        );
      }
      _memoryStore.removeWhere((i) => i.isPurchased);
    } catch (e) {
      throw DatabaseException('Failed to clear purchased items: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_filter.dart';
import '../../domain/entities/food_stats.dart';
import '../../domain/entities/food_status.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/product_reminder.dart';
import '../../domain/entities/storage_location.dart';
import '../models/food_item_model.dart';

abstract class FoodLocalDataSource {
  Future<List<FoodItemModel>> getFoodItems({
    FoodFilter? filter,
    int warningDays = 2,
  });

  Future<FoodItemModel?> getFoodItemById(String id);

  Future<FoodItemModel?> getFoodItemByBarcode(String barcode);

  Future<void> insertFoodItem(FoodItemModel item);

  Future<void> updateFoodItem(FoodItemModel item);

  Future<void> deleteFoodItem(String id);

  Future<void> consumeFoodItem(String id, double consumedQuantity);

  Future<void> toggleFavorite(String id);

  Future<List<FoodItemModel>> getExpiringFoodItems({int warningDays = 2});

  Future<List<FoodItemModel>> getLowStockItems();

  Future<List<FoodItemModel>> getRecurringGroceries();

  Future<FoodStats> getFoodStats({int warningDays = 2});

  Future<List<ProductReminder>> getRemindersForProduct(String productId);

  Future<void> saveReminders(String productId, List<ProductReminder> reminders);

  Future<void> deleteRemindersForProduct(String productId);

  Future<void> dismissReminder(String reminderId);

  Future<List<ProductReminder>> getAllActiveReminders();

  Future<void> seedSampleData();

  Future<void> clearAllData();
}

class FoodLocalDataSourceImpl implements FoodLocalDataSource {
  final DatabaseHelper _dbHelper;
  static final List<FoodItemModel> _memoryStore = [];
  static bool _seededInMemory = false;

  FoodLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<FoodItemModel>> getFoodItems({
    FoodFilter? filter,
    int warningDays = 2,
  }) async {
    try {
      final db = await _dbHelper.database;
      final f = filter ?? const FoodFilter();

      if (db != null) {
        final whereClauses = <String>[];
        final whereArgs = <dynamic>[];

        // Consumed filter
        if (!f.includeConsumed && f.status != FoodStatus.consumed) {
          whereClauses.add('is_consumed = 0');
        } else if (f.status == FoodStatus.consumed) {
          whereClauses.add('is_consumed = 1');
        }

        // Category filter
        if (f.category != null) {
          whereClauses.add('category = ?');
          whereArgs.add(f.category!.name);
        }

        // Storage Location filter
        if (f.storageLocation != null) {
          whereClauses.add('storage_location = ?');
          whereArgs.add(f.storageLocation!.name);
        }

        // Favorite filter
        if (f.isFavorite == true) {
          whereClauses.add('is_favorite = 1');
        }

        // Search Query
        if (f.searchQuery.trim().isNotEmpty) {
          whereClauses.add('(name LIKE ? OR brand LIKE ? OR notes LIKE ? OR barcode LIKE ?)');
          final queryArg = '%${f.searchQuery.trim()}%';
          whereArgs.add(queryArg);
          whereArgs.add(queryArg);
          whereArgs.add(queryArg);
          whereArgs.add(queryArg);
        }

        // Sort order
        String orderBy;
        switch (f.sortOption) {
          case FoodSortOption.expiryDateAsc:
            orderBy = 'CASE WHEN expiry_date IS NULL THEN 1 ELSE 0 END, expiry_date ASC';
            break;
          case FoodSortOption.expiryDateDesc:
            orderBy = 'CASE WHEN expiry_date IS NULL THEN 1 ELSE 0 END, expiry_date DESC';
            break;
          case FoodSortOption.nameAsc:
            orderBy = 'name ASC';
            break;
          case FoodSortOption.nameDesc:
            orderBy = 'name DESC';
            break;
          case FoodSortOption.dateAddedDesc:
            orderBy = 'created_at DESC';
            break;
          case FoodSortOption.dateAddedAsc:
            orderBy = 'created_at ASC';
            break;
          case FoodSortOption.quantityDesc:
            orderBy = 'remaining_quantity DESC';
            break;
          case FoodSortOption.quantityAsc:
            orderBy = 'remaining_quantity ASC';
            break;
          case FoodSortOption.categoryAsc:
            orderBy = 'category ASC';
            break;
        }

        final whereString =
            whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

        final results = await db.query(
          AppConstants.foodTable,
          where: whereString,
          whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
          orderBy: orderBy,
        );

        var items = results.map((e) => FoodItemModel.fromMap(e)).toList();

        // Low stock filter post-processing
        if (f.isLowStock == true) {
          items = items.where((i) => i.isLowStock()).toList();
        }

        // Post-filter by computed status if requested
        if (f.status != null && f.status != FoodStatus.consumed) {
          items = items
              .where((item) => item.getStatus(warningDays: warningDays) == f.status)
              .toList();
        }

        return items;
      }

      // In-Memory fallback implementation
      if (!_seededInMemory && _memoryStore.isEmpty) {
        await seedSampleData();
      }

      var items = List<FoodItemModel>.from(_memoryStore);

      // Consumed filter
      if (!f.includeConsumed && f.status != FoodStatus.consumed) {
        items = items.where((i) => !i.isConsumed).toList();
      } else if (f.status == FoodStatus.consumed) {
        items = items.where((i) => i.isConsumed).toList();
      }

      // Category filter
      if (f.category != null) {
        items = items.where((i) => i.category == f.category).toList();
      }

      // Storage Location filter
      if (f.storageLocation != null) {
        items = items.where((i) => i.storageLocation == f.storageLocation).toList();
      }

      // Favorite filter
      if (f.isFavorite == true) {
        items = items.where((i) => i.isFavorite).toList();
      }

      // Low stock filter
      if (f.isLowStock == true) {
        items = items.where((i) => i.isLowStock()).toList();
      }

      // Search Query filter
      if (f.searchQuery.trim().isNotEmpty) {
        final query = f.searchQuery.trim().toLowerCase();
        items = items.where((i) {
          final matchName = i.name.toLowerCase().contains(query);
          final matchBrand = i.brand?.toLowerCase().contains(query) ?? false;
          final matchNotes = i.notes?.toLowerCase().contains(query) ?? false;
          final matchBarcode = i.barcode?.toLowerCase().contains(query) ?? false;
          return matchName || matchBrand || matchNotes || matchBarcode;
        }).toList();
      }

      // Status filter
      if (f.status != null && f.status != FoodStatus.consumed) {
        items = items
            .where((item) => item.getStatus(warningDays: warningDays) == f.status)
            .toList();
      }

      // Sorting
      switch (f.sortOption) {
        case FoodSortOption.expiryDateAsc:
          items.sort((a, b) {
            if (a.expiryDate == null && b.expiryDate == null) return 0;
            if (a.expiryDate == null) return 1;
            if (b.expiryDate == null) return -1;
            return a.expiryDate!.compareTo(b.expiryDate!);
          });
          break;
        case FoodSortOption.expiryDateDesc:
          items.sort((a, b) {
            if (a.expiryDate == null && b.expiryDate == null) return 0;
            if (a.expiryDate == null) return 1;
            if (b.expiryDate == null) return -1;
            return b.expiryDate!.compareTo(a.expiryDate!);
          });
          break;
        case FoodSortOption.nameAsc:
          items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case FoodSortOption.nameDesc:
          items.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case FoodSortOption.dateAddedDesc:
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case FoodSortOption.dateAddedAsc:
          items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case FoodSortOption.quantityDesc:
          items.sort((a, b) => b.remainingQuantity.compareTo(a.remainingQuantity));
          break;
        case FoodSortOption.quantityAsc:
          items.sort((a, b) => a.remainingQuantity.compareTo(b.remainingQuantity));
          break;
        case FoodSortOption.categoryAsc:
          items.sort((a, b) => a.category.label.toLowerCase().compareTo(b.category.label.toLowerCase()));
          break;
      }

      return items;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to get food items: $e');
    }
  }

  @override
  Future<FoodItemModel?> getFoodItemById(String id) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        final results = await db.query(
          AppConstants.foodTable,
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (results.isEmpty) return null;
        return FoodItemModel.fromMap(results.first);
      }

      final index = _memoryStore.indexWhere((i) => i.id == id);
      return index != -1 ? _memoryStore[index] : null;
    } catch (e) {
      throw DatabaseException('Failed to find food item with id $id: $e');
    }
  }

  @override
  Future<FoodItemModel?> getFoodItemByBarcode(String barcode) async {
    try {
      final cleanBarcode = barcode.trim();
      if (cleanBarcode.isEmpty) return null;

      final db = await _dbHelper.database;
      if (db != null) {
        final results = await db.query(
          AppConstants.foodTable,
          where: 'barcode = ? AND is_consumed = 0',
          whereArgs: [cleanBarcode],
          orderBy: 'created_at DESC',
          limit: 1,
        );

        if (results.isEmpty) return null;
        return FoodItemModel.fromMap(results.first);
      }

      final index = _memoryStore.indexWhere((i) => i.barcode == cleanBarcode && !i.isConsumed);
      return index != -1 ? _memoryStore[index] : null;
    } catch (e) {
      throw DatabaseException('Failed to find grocery item by barcode $barcode: $e');
    }
  }

  @override
  Future<void> insertFoodItem(FoodItemModel item) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.insert(
          AppConstants.foodTable,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await _queueSync(
          db,
          action: 'insert',
          entityType: 'product',
          entityId: item.id,
          payload: item.toMap(),
        );
      }

      final idx = _memoryStore.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        _memoryStore[idx] = item;
      } else {
        _memoryStore.add(item);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to insert product: $e');
    }
  }

  @override
  Future<void> updateFoodItem(FoodItemModel item) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        final count = await db.update(
          AppConstants.foodTable,
          item.toMap(),
          where: 'id = ?',
          whereArgs: [item.id],
        );
        if (count == 0) {
          throw NotFoundException('Product with id ${item.id} not found to update');
        }
        await _queueSync(
          db,
          action: 'update',
          entityType: 'product',
          entityId: item.id,
          payload: item.toMap(),
        );
      }

      final idx = _memoryStore.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        _memoryStore[idx] = item;
      } else if (db == null) {
        throw NotFoundException('Product with id ${item.id} not found to update');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteFoodItem(String id) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.delete(
          AppConstants.foodTable,
          where: 'id = ?',
          whereArgs: [id],
        );
        await deleteRemindersForProduct(id);
        await _queueSync(
          db,
          action: 'delete',
          entityType: 'product',
          entityId: id,
          payload: {'id': id},
        );
      }
      _memoryStore.removeWhere((i) => i.id == id);
      _memoryReminders.removeWhere((r) => r.productId == id);
    } catch (e) {
      throw DatabaseException('Failed to delete product: $e');
    }
  }

  @override
  Future<void> consumeFoodItem(String id, double consumedQuantity) async {
    try {
      final db = await _dbHelper.database;
      final item = await getFoodItemById(id);
      if (item == null) {
        throw NotFoundException('Product with id $id not found');
      }

      final newQuantity = (item.remainingQuantity - consumedQuantity).clamp(0.0, double.infinity);
      final isFullyConsumed = newQuantity <= 0;

      if (db != null) {
        await db.update(
          AppConstants.foodTable,
          {
            'remaining_quantity': newQuantity,
            'is_consumed': isFullyConsumed ? 1 : 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await _queueSync(
          db,
          action: 'update',
          entityType: 'product',
          entityId: id,
          payload: {
            'id': id,
            'remaining_quantity': newQuantity,
            'is_consumed': isFullyConsumed ? 1 : 0,
          },
        );
      }

      final updated = item.copyWith(
        remainingQuantity: newQuantity,
        isConsumed: isFullyConsumed,
        updatedAt: DateTime.now(),
      );
      final idx = _memoryStore.indexWhere((i) => i.id == id);
      if (idx >= 0) {
        _memoryStore[idx] = FoodItemModel.fromEntity(updated);
      }
    } catch (e) {
      throw DatabaseException('Failed to consume product: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    try {
      final item = await getFoodItemById(id);
      if (item == null) return;
      final newFav = !item.isFavorite;

      final db = await _dbHelper.database;
      if (db != null) {
        await db.update(
          AppConstants.foodTable,
          {
            'is_favorite': newFav ? 1 : 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      final updated = item.copyWith(isFavorite: newFav, updatedAt: DateTime.now());
      final idx = _memoryStore.indexWhere((i) => i.id == id);
      if (idx >= 0) {
        _memoryStore[idx] = FoodItemModel.fromEntity(updated);
      }
    } catch (e) {
      throw DatabaseException('Failed to toggle favorite for product: $e');
    }
  }

  @override
  Future<List<FoodItemModel>> getExpiringFoodItems({int warningDays = 2}) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final threshold = DateTime(now.year, now.month, now.day + warningDays, 23, 59, 59);

      if (db != null) {
        final results = await db.query(
          AppConstants.foodTable,
          where: 'is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date <= ?',
          whereArgs: [threshold.toIso8601String()],
          orderBy: 'expiry_date ASC',
        );

        return results.map((e) => FoodItemModel.fromMap(e)).toList();
      }

      return _memoryStore
          .where((i) =>
              !i.isConsumed &&
              i.expiryDate != null &&
              i.expiryDate!.isBefore(threshold))
          .toList()
        ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    } catch (e) {
      throw DatabaseException('Failed to query expiring products: $e');
    }
  }

  @override
  Future<List<FoodItemModel>> getLowStockItems() async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        final results = await db.query(
          AppConstants.foodTable,
          where:
              'is_consumed = 0 AND minimum_stock IS NOT NULL AND remaining_quantity <= minimum_stock',
          orderBy: 'remaining_quantity ASC',
        );
        return results.map((e) => FoodItemModel.fromMap(e)).toList();
      }

      return _memoryStore
          .where((i) => !i.isConsumed && i.isLowStock())
          .toList()
        ..sort((a, b) => a.remainingQuantity.compareTo(b.remainingQuantity));
    } catch (e) {
      throw DatabaseException('Failed to query low stock items: $e');
    }
  }

  @override
  Future<List<FoodItemModel>> getRecurringGroceries() async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        final results = await db.query(
          AppConstants.foodTable,
          where: 'is_recurring = 1',
          orderBy: 'next_reminder_date ASC',
        );
        return results.map((e) => FoodItemModel.fromMap(e)).toList();
      }

      return _memoryStore.where((i) => i.isRecurring).toList();
    } catch (e) {
      throw DatabaseException('Failed to query recurring groceries: $e');
    }
  }

  @override
  Future<FoodStats> getFoodStats({int warningDays = 2}) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int totalActive = 0;
      int expiringSoon = 0;
      int expiresToday = 0;
      int expiringWithin7Days = 0;
      int expiringWithin30Days = 0;
      int expired = 0;
      int noExpiryDate = 0;
      int fresh = 0;
      int totalConsumed = 0;

      if (db != null) {
        final results = await db.query(AppConstants.foodTable);

        for (final row in results) {
          final isConsumed = (row['is_consumed'] as int? ?? 0) == 1;
          if (isConsumed) {
            totalConsumed++;
          } else {
            totalActive++;
            final rawExpiry = row['expiry_date'] as String?;
            if (rawExpiry == null || rawExpiry.trim().isEmpty) {
              noExpiryDate++;
              fresh++;
              continue;
            }

            final expiryDate = DateTime.parse(rawExpiry);
            final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
            final days = expiryDay.difference(today).inDays;

            if (days < 0) {
              expired++;
            } else {
              if (days == 0) {
                expiresToday++;
              }
              if (days <= 7) {
                expiringWithin7Days++;
              }
              if (days <= 30) {
                expiringWithin30Days++;
              }
              if (days <= warningDays) {
                expiringSoon++;
              } else {
                fresh++;
              }
            }
          }
        }
      } else {
        if (!_seededInMemory && _memoryStore.isEmpty) {
          await seedSampleData();
        }

        for (final item in _memoryStore) {
          if (item.isConsumed) {
            totalConsumed++;
          } else {
            totalActive++;
            if (item.expiryDate == null) {
              noExpiryDate++;
              fresh++;
              continue;
            }

            final expiryDate = item.expiryDate!;
            final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
            final days = expiryDay.difference(today).inDays;

            if (days < 0) {
              expired++;
            } else {
              if (days == 0) {
                expiresToday++;
              }
              if (days <= 7) {
                expiringWithin7Days++;
              }
              if (days <= 30) {
                expiringWithin30Days++;
              }
              if (days <= warningDays) {
                expiringSoon++;
              } else {
                fresh++;
              }
            }
          }
        }
      }

      return FoodStats(
        totalActive: totalActive,
        expiringSoon: expiringSoon,
        expiresToday: expiresToday,
        expiringWithin7Days: expiringWithin7Days,
        expiringWithin30Days: expiringWithin30Days,
        expired: expired,
        noExpiryDate: noExpiryDate,
        fresh: fresh,
        totalConsumed: totalConsumed,
      );
    } catch (e) {
      throw DatabaseException('Failed to calculate product stats: $e');
    }
  }

  static final List<ProductReminder> _memoryReminders = [];

  @override
  Future<List<ProductReminder>> getRemindersForProduct(String productId) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        final results = await db.query(
          AppConstants.remindersTable,
          where: 'product_id = ?',
          whereArgs: [productId],
          orderBy: 'reminder_date ASC',
        );
        return results.map((r) => ProductReminder.fromMap(r)).toList();
      }
      return _memoryReminders.where((r) => r.productId == productId).toList();
    } catch (e) {
      throw DatabaseException('Failed to get reminders for product $productId: $e');
    }
  }

  @override
  Future<void> saveReminders(String productId, List<ProductReminder> reminders) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.transaction((txn) async {
          await txn.delete(
            AppConstants.remindersTable,
            where: 'product_id = ?',
            whereArgs: [productId],
          );
          for (final rem in reminders) {
            await txn.insert(
              AppConstants.remindersTable,
              rem.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      }
      _memoryReminders.removeWhere((r) => r.productId == productId);
      _memoryReminders.addAll(reminders);
    } catch (e) {
      throw DatabaseException('Failed to save reminders: $e');
    }
  }

  @override
  Future<void> deleteRemindersForProduct(String productId) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.delete(
          AppConstants.remindersTable,
          where: 'product_id = ?',
          whereArgs: [productId],
        );
      }
      _memoryReminders.removeWhere((r) => r.productId == productId);
    } catch (e) {
      throw DatabaseException('Failed to delete reminders for product $productId: $e');
    }
  }

  @override
  Future<void> dismissReminder(String reminderId) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.update(
          AppConstants.remindersTable,
          {'is_enabled': 0, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [reminderId],
        );
      }
      final idx = _memoryReminders.indexWhere((r) => r.id == reminderId);
      if (idx >= 0) {
        _memoryReminders[idx] = _memoryReminders[idx].copyWith(isEnabled: false);
      }
    } catch (e) {
      throw DatabaseException('Failed to dismiss reminder $reminderId: $e');
    }
  }

  @override
  Future<List<ProductReminder>> getAllActiveReminders() async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        final results = await db.query(
          AppConstants.remindersTable,
          where: 'is_enabled = 1',
          orderBy: 'reminder_date ASC',
        );
        return results.map((r) => ProductReminder.fromMap(r)).toList();
      }
      return _memoryReminders.where((r) => r.isEnabled).toList();
    } catch (e) {
      throw DatabaseException('Failed to get active reminders: $e');
    }
  }

  Future<void> _queueSync(
    Database? db, {
    required String action,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    if (db == null) return;
    try {
      await db.insert(
        AppConstants.syncQueueTable,
        {
          'id': '${DateTime.now().millisecondsSinceEpoch}_$entityId',
          'action': action,
          'entity_type': entityType,
          'entity_id': entityId,
          'payload': jsonEncode(payload),
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  @override
  Future<void> seedSampleData() async {
    try {
      final db = await _dbHelper.database;

      if (db != null) {
        // 1. Quick check if products already exist in the database
        final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppConstants.foodTable} LIMIT 1',
          ),
        );

        if (count != null && count > 0) return;
      } else {
        if (_seededInMemory && _memoryStore.isNotEmpty) return;
      }

      final now = DateTime.now();

      // Seed realistic grocery items across all 8 grocery categories with price & location
      final samples = [
        // 1. Urgent: Use Today / Expiring Soon Items
        FoodItemModel(
          id: 'seed-milk',
          name: 'Whole Milk',
          category: FoodCategory.dairy,
          purchaseDate: now.subtract(const Duration(days: 4)),
          expiryDate: now.add(const Duration(hours: 8)),
          remainingQuantity: 500.0,
          unit: FoodUnit.ml,
          minimumStock: 1000.0,
          price: 64.0,
          storageLocation: StorageLocation.fridge,
          isFavorite: true,
          isRecurring: true,
          recurringIntervalDays: 7,
          nextReminderDate: now.add(const Duration(days: 3)),
          notes: 'Fresh pasteurized whole milk, opened bottle.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 4)),
          updatedAt: now.subtract(const Duration(days: 4)),
        ),
        FoodItemModel(
          id: 'seed-bread',
          name: 'Sourdough Bread',
          category: FoodCategory.flourAndBaking,
          purchaseDate: now.subtract(const Duration(days: 3)),
          expiryDate: now.add(const Duration(hours: 10)),
          remainingQuantity: 1.0,
          unit: FoodUnit.pieces,
          minimumStock: 1.0,
          price: 90.0,
          storageLocation: StorageLocation.kitchenCabinet,
          notes: 'Artisan bakery sourdough loaf.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        FoodItemModel(
          id: 'seed-greek-yogurt',
          name: 'Greek Yogurt',
          category: FoodCategory.dairy,
          purchaseDate: now.subtract(const Duration(days: 3)),
          expiryDate: now.add(const Duration(days: 1)),
          remainingQuantity: 250.0,
          unit: FoodUnit.grams,
          minimumStock: 400.0,
          price: 120.0,
          storageLocation: StorageLocation.fridge,
          notes: 'Natural thick probiotic Greek yogurt.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        FoodItemModel(
          id: 'seed-biscuits',
          name: 'Digestive Biscuits',
          category: FoodCategory.snacksAndPackaged,
          purchaseDate: now.subtract(const Duration(days: 5)),
          expiryDate: now.add(const Duration(days: 2)),
          remainingQuantity: 200.0,
          unit: FoodUnit.grams,
          minimumStock: 200.0,
          price: 45.0,
          storageLocation: StorageLocation.pantry,
          notes: 'Crispy wholemeal digestive biscuits.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),

        // 2. Grains & Pulses
        FoodItemModel(
          id: 'seed-basmati-rice',
          name: 'Basmati Rice',
          category: FoodCategory.grainsAndPulses,
          purchaseDate: now.subtract(const Duration(days: 10)),
          expiryDate: now.add(const Duration(days: 180)),
          remainingQuantity: 5.0,
          unit: FoodUnit.kg,
          minimumStock: 2.0,
          price: 420.0,
          storageLocation: StorageLocation.pantry,
          isFavorite: true,
          isRecurring: true,
          recurringIntervalDays: 30,
          nextReminderDate: now.add(const Duration(days: 20)),
          notes: 'Premium aged long-grain royal basmati rice.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 10)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        FoodItemModel(
          id: 'seed-red-lentils',
          name: 'Red Lentils (Masoor Dal)',
          category: FoodCategory.grainsAndPulses,
          purchaseDate: now.subtract(const Duration(days: 7)),
          expiryDate: now.add(const Duration(days: 120)),
          remainingQuantity: 1.0,
          unit: FoodUnit.kg,
          minimumStock: 1.0,
          price: 130.0,
          storageLocation: StorageLocation.pantry,
          notes: 'Organic split red lentils, fast cooking.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now.subtract(const Duration(days: 7)),
        ),
        FoodItemModel(
          id: 'seed-chickpeas',
          name: 'Chickpeas (Garbanzo)',
          category: FoodCategory.grainsAndPulses,
          purchaseDate: now.subtract(const Duration(days: 12)),
          expiryDate: now.add(const Duration(days: 90)),
          remainingQuantity: 1.0,
          unit: FoodUnit.kg,
          minimumStock: 1.0,
          price: 140.0,
          storageLocation: StorageLocation.pantry,
          notes: 'Dry whole white chickpeas for curries and salads.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 12)),
          updatedAt: now.subtract(const Duration(days: 12)),
        ),
        FoodItemModel(
          id: 'seed-oats',
          name: 'Rolled Oats',
          category: FoodCategory.grainsAndPulses,
          purchaseDate: now.subtract(const Duration(days: 5)),
          expiryDate: now.add(const Duration(days: 60)),
          remainingQuantity: 500.0,
          unit: FoodUnit.grams,
          minimumStock: 500.0,
          price: 180.0,
          storageLocation: StorageLocation.pantry,
          isFavorite: true,
          notes: '100% whole grain rolled porridge oats.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),

        // 3. Flour & Baking
        FoodItemModel(
          id: 'seed-wheat-flour',
          name: 'Whole Wheat Flour (Atta)',
          category: FoodCategory.flourAndBaking,
          purchaseDate: now.subtract(const Duration(days: 8)),
          expiryDate: now.add(const Duration(days: 90)),
          remainingQuantity: 5.0,
          unit: FoodUnit.kg,
          minimumStock: 5.0,
          price: 240.0,
          storageLocation: StorageLocation.pantry,
          isFavorite: true,
          isRecurring: true,
          recurringIntervalDays: 30,
          nextReminderDate: now.add(const Duration(days: 22)),
          notes: 'Stone ground whole wheat flour for flatbreads & rotis.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 8)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        FoodItemModel(
          id: 'seed-sugar',
          name: 'Cane Sugar',
          category: FoodCategory.flourAndBaking,
          purchaseDate: now.subtract(const Duration(days: 15)),
          expiryDate: now.add(const Duration(days: 365)),
          remainingQuantity: 1.0,
          unit: FoodUnit.kg,
          price: 55.0,
          storageLocation: StorageLocation.pantry,
          notes: 'Pure unrefined cane sugar in pantry jar.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 15)),
          updatedAt: now.subtract(const Duration(days: 15)),
        ),
        FoodItemModel(
          id: 'seed-baking-powder',
          name: 'Baking Powder',
          category: FoodCategory.flourAndBaking,
          purchaseDate: now.subtract(const Duration(days: 20)),
          expiryDate: now.add(const Duration(days: 180)),
          remainingQuantity: 100.0,
          unit: FoodUnit.grams,
          price: 45.0,
          storageLocation: StorageLocation.kitchenCabinet,
          notes: 'Double acting baking powder tin.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),

        // 4. Spices
        FoodItemModel(
          id: 'seed-salt',
          name: 'Iodized Table Salt',
          category: FoodCategory.spices,
          purchaseDate: now.subtract(const Duration(days: 30)),
          expiryDate: now.add(const Duration(days: 730)),
          remainingQuantity: 1.0,
          unit: FoodUnit.kg,
          price: 28.0,
          storageLocation: StorageLocation.kitchenCabinet,
          notes: 'Essential fine cooking salt.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 30)),
        ),
        FoodItemModel(
          id: 'seed-turmeric',
          name: 'Turmeric Powder',
          category: FoodCategory.spices,
          purchaseDate: now.subtract(const Duration(days: 14)),
          expiryDate: now.add(const Duration(days: 365)),
          remainingQuantity: 200.0,
          unit: FoodUnit.grams,
          price: 70.0,
          storageLocation: StorageLocation.kitchenCabinet,
          notes: 'High curcumin golden turmeric powder.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 14)),
          updatedAt: now.subtract(const Duration(days: 14)),
        ),
        FoodItemModel(
          id: 'seed-pepper',
          name: 'Black Pepper',
          category: FoodCategory.spices,
          purchaseDate: now.subtract(const Duration(days: 20)),
          expiryDate: now.add(const Duration(days: 365)),
          remainingQuantity: 100.0,
          unit: FoodUnit.grams,
          price: 95.0,
          storageLocation: StorageLocation.kitchenCabinet,
          notes: 'Whole Tellicherry black peppercorns.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),
        FoodItemModel(
          id: 'seed-cumin',
          name: 'Ground Cumin',
          category: FoodCategory.spices,
          purchaseDate: now.subtract(const Duration(days: 15)),
          expiryDate: now.add(const Duration(days: 180)),
          remainingQuantity: 150.0,
          unit: FoodUnit.grams,
          price: 85.0,
          storageLocation: StorageLocation.kitchenCabinet,
          notes: 'Aromatic roasted ground cumin spice jar.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 15)),
          updatedAt: now.subtract(const Duration(days: 15)),
        ),

        // 5. Oils & Ghee
        FoodItemModel(
          id: 'seed-olive-oil',
          name: 'Extra Virgin Olive Oil',
          category: FoodCategory.oils,
          purchaseDate: now.subtract(const Duration(days: 10)),
          expiryDate: now.add(const Duration(days: 180)),
          remainingQuantity: 1.0,
          unit: FoodUnit.litre,
          price: 750.0,
          storageLocation: StorageLocation.pantry,
          isFavorite: true,
          notes: 'Cold pressed extra virgin olive oil.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 10)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        FoodItemModel(
          id: 'seed-sunflower-oil',
          name: 'Sunflower Cooking Oil',
          category: FoodCategory.oils,
          purchaseDate: now.subtract(const Duration(days: 12)),
          expiryDate: now.add(const Duration(days: 240)),
          remainingQuantity: 2.0,
          unit: FoodUnit.litre,
          minimumStock: 1.0,
          price: 290.0,
          storageLocation: StorageLocation.pantry,
          isRecurring: true,
          recurringIntervalDays: 45,
          nextReminderDate: now.add(const Duration(days: 33)),
          notes: 'Refined sunflower oil bottle for frying and cooking.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 12)),
          updatedAt: now.subtract(const Duration(days: 12)),
        ),
        FoodItemModel(
          id: 'seed-ghee',
          name: 'Pure Ghee',
          category: FoodCategory.oils,
          purchaseDate: now.subtract(const Duration(days: 18)),
          expiryDate: now.add(const Duration(days: 180)),
          remainingQuantity: 500.0,
          unit: FoodUnit.grams,
          price: 360.0,
          storageLocation: StorageLocation.kitchenCabinet,
          isFavorite: true,
          notes: 'Traditional clarified butter ghee jar.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 18)),
          updatedAt: now.subtract(const Duration(days: 18)),
        ),

        // 6. Snacks & Packaged Foods
        FoodItemModel(
          id: 'seed-pasta',
          name: 'Penne Rigate Pasta',
          category: FoodCategory.snacksAndPackaged,
          purchaseDate: now.subtract(const Duration(days: 6)),
          expiryDate: now.add(const Duration(days: 120)),
          remainingQuantity: 500.0,
          unit: FoodUnit.grams,
          price: 110.0,
          storageLocation: StorageLocation.pantry,
          notes: 'Italian durum wheat semolina pasta.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 6)),
          updatedAt: now.subtract(const Duration(days: 6)),
        ),

        // 7. Beverages
        FoodItemModel(
          id: 'seed-tea',
          name: 'Green Tea Bags',
          category: FoodCategory.beverages,
          purchaseDate: now.subtract(const Duration(days: 14)),
          expiryDate: now.add(const Duration(days: 180)),
          remainingQuantity: 25.0,
          unit: FoodUnit.pieces,
          price: 190.0,
          storageLocation: StorageLocation.kitchenCabinet,
          notes: 'Organic pure green tea leaves in envelopes.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 14)),
          updatedAt: now.subtract(const Duration(days: 14)),
        ),
        FoodItemModel(
          id: 'seed-coffee',
          name: 'Roasted Coffee Beans',
          category: FoodCategory.beverages,
          purchaseDate: now.subtract(const Duration(days: 8)),
          expiryDate: now.add(const Duration(days: 90)),
          remainingQuantity: 250.0,
          unit: FoodUnit.grams,
          price: 320.0,
          storageLocation: StorageLocation.kitchenCabinet,
          isFavorite: true,
          notes: 'Medium roast 100% Arabica beans in airtight bag.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 8)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),

        // 8. 1 Expired item
        FoodItemModel(
          id: 'seed-expired-cream',
          name: 'Opened Cream Cheese',
          category: FoodCategory.dairy,
          purchaseDate: now.subtract(const Duration(days: 20)),
          expiryDate: now.subtract(const Duration(days: 1)),
          remainingQuantity: 150.0,
          unit: FoodUnit.grams,
          price: 140.0,
          storageLocation: StorageLocation.fridge,
          notes: 'Past recommended shelf life.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),

        // 9. Rescued (Consumed / Used) items
        FoodItemModel(
          id: 'seed-consumed-1',
          name: 'Sourdough Loaf',
          category: FoodCategory.flourAndBaking,
          purchaseDate: now.subtract(const Duration(days: 7)),
          expiryDate: now.subtract(const Duration(days: 4)),
          remainingQuantity: 0.0,
          unit: FoodUnit.pieces,
          price: 90.0,
          isConsumed: true,
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now.subtract(const Duration(days: 4)),
        ),
        FoodItemModel(
          id: 'seed-consumed-2',
          name: 'Oat Milk Carton',
          category: FoodCategory.dairy,
          purchaseDate: now.subtract(const Duration(days: 8)),
          expiryDate: now.subtract(const Duration(days: 3)),
          remainingQuantity: 0.0,
          unit: FoodUnit.litre,
          price: 180.0,
          isConsumed: true,
          createdAt: now.subtract(const Duration(days: 8)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        FoodItemModel(
          id: 'seed-consumed-3',
          name: 'Brown Rice Pack',
          category: FoodCategory.grainsAndPulses,
          purchaseDate: now.subtract(const Duration(days: 15)),
          expiryDate: now.subtract(const Duration(days: 2)),
          remainingQuantity: 0.0,
          unit: FoodUnit.kg,
          price: 160.0,
          isConsumed: true,
          createdAt: now.subtract(const Duration(days: 15)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        FoodItemModel(
          id: 'seed-consumed-4',
          name: 'Cooking Butter',
          category: FoodCategory.dairy,
          purchaseDate: now.subtract(const Duration(days: 12)),
          expiryDate: now.subtract(const Duration(days: 2)),
          remainingQuantity: 0.0,
          unit: FoodUnit.grams,
          price: 58.0,
          isConsumed: true,
          createdAt: now.subtract(const Duration(days: 12)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        FoodItemModel(
          id: 'seed-consumed-5',
          name: 'Sea Salt Shaker',
          category: FoodCategory.spices,
          purchaseDate: now.subtract(const Duration(days: 30)),
          expiryDate: now.subtract(const Duration(days: 1)),
          remainingQuantity: 0.0,
          unit: FoodUnit.containers,
          price: 45.0,
          isConsumed: true,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        FoodItemModel(
          id: 'seed-consumed-6',
          name: 'Chai Tea Bags',
          category: FoodCategory.beverages,
          purchaseDate: now.subtract(const Duration(days: 20)),
          expiryDate: now.subtract(const Duration(days: 3)),
          remainingQuantity: 0.0,
          unit: FoodUnit.pieces,
          price: 80.0,
          isConsumed: true,
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        FoodItemModel(
          id: 'seed-consumed-7',
          name: 'Wheat Crackers',
          category: FoodCategory.snacksAndPackaged,
          purchaseDate: now.subtract(const Duration(days: 10)),
          expiryDate: now.subtract(const Duration(days: 1)),
          remainingQuantity: 0.0,
          unit: FoodUnit.grams,
          price: 60.0,
          isConsumed: true,
          createdAt: now.subtract(const Duration(days: 10)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),

        // 10. Universal Non-Expiring & Specialty Products
        FoodItemModel(
          id: 'seed-headphones',
          name: 'Wireless Bluetooth Headphones',
          brand: 'Sony',
          barcode: '4548736100234',
          category: FoodCategory.electronicsAndHardware,
          subcategory: 'Audio',
          purchaseDate: now.subtract(const Duration(days: 60)),
          manufacturingDate: now.subtract(const Duration(days: 120)),
          expiryDate: null,
          reminderEnabled: false,
          remainingQuantity: 1.0,
          unit: FoodUnit.pieces,
          price: 2999.0,
          storageLocation: StorageLocation.pantry,
          notes: 'High resolution wireless headphones. Does not expire.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 60)),
          updatedAt: now.subtract(const Duration(days: 60)),
        ),
        FoodItemModel(
          id: 'seed-tshirt',
          name: 'Cotton Crewneck T-Shirt',
          brand: 'Puma',
          barcode: '4063697200112',
          category: FoodCategory.other,
          subcategory: 'Apparel',
          purchaseDate: now.subtract(const Duration(days: 15)),
          manufacturingDate: now.subtract(const Duration(days: 45)),
          expiryDate: null,
          reminderEnabled: false,
          remainingQuantity: 2.0,
          unit: FoodUnit.pieces,
          price: 799.0,
          storageLocation: StorageLocation.pantry,
          notes: 'Breathable activewear t-shirt. Does not expire.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 15)),
          updatedAt: now.subtract(const Duration(days: 15)),
        ),
        FoodItemModel(
          id: 'seed-paracetamol',
          name: 'Paracetamol 500mg Tablets',
          brand: 'Crocin',
          barcode: '8901117101011',
          category: FoodCategory.medicines,
          subcategory: 'Analgesics',
          purchaseDate: now.subtract(const Duration(days: 30)),
          manufacturingDate: now.subtract(const Duration(days: 90)),
          expiryDate: now.add(const Duration(days: 30)),
          reminderEnabled: true,
          reminderDaysBefore: const [7, 1],
          remainingQuantity: 10.0,
          unit: FoodUnit.pieces,
          price: 32.0,
          storageLocation: StorageLocation.pantry,
          notes: 'Fast fever and headache relief.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 30)),
        ),
        FoodItemModel(
          id: 'seed-facecream',
          name: 'Herbal Moisturizing Cream',
          brand: 'Himalaya',
          barcode: '8901138830114',
          category: FoodCategory.personalCare,
          subcategory: 'Skincare',
          purchaseDate: now.subtract(const Duration(days: 20)),
          manufacturingDate: now.subtract(const Duration(days: 60)),
          expiryDate: now.add(const Duration(days: 6)),
          reminderEnabled: true,
          reminderDaysBefore: const [7, 3, 1],
          remainingQuantity: 1.0,
          unit: FoodUnit.pieces,
          price: 180.0,
          storageLocation: StorageLocation.pantry,
          notes: 'Daily nourishing facial cream.',
          isConsumed: false,
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),
      ];

      for (final sample in samples) {
        await insertFoodItem(sample);
      }
      _seededInMemory = true;
    } catch (e) {
      debugPrint('Warning: Failed to seed sample food data: $e');
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.delete(AppConstants.foodTable);
      }
      _memoryStore.clear();
      _seededInMemory = false;
    } catch (e) {
      throw DatabaseException('Failed to clear database: $e');
    }
  }
}

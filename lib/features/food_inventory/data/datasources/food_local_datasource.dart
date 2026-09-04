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

        // Grocery Category filter
        if (f.category != null) {
          whereClauses.add('category = ?');
          whereArgs.add(f.category!.name);
        } else {
          final groceryCats = FoodCategory.groceryCategoryNames;
          final placeholders = List.filled(groceryCats.length, '?').join(', ');
          whereClauses.add('category IN ($placeholders)');
          whereArgs.addAll(groceryCats);
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
          whereClauses.add('(name LIKE ? OR notes LIKE ? OR barcode LIKE ?)');
          final queryArg = '%${f.searchQuery.trim()}%';
          whereArgs.add(queryArg);
          whereArgs.add(queryArg);
          whereArgs.add(queryArg);
        }

        // Sort order
        String orderBy;
        switch (f.sortOption) {
          case FoodSortOption.expiryDateAsc:
            orderBy = 'expiry_date ASC';
            break;
          case FoodSortOption.expiryDateDesc:
            orderBy = 'expiry_date DESC';
            break;
          case FoodSortOption.nameAsc:
            orderBy = 'name ASC';
            break;
          case FoodSortOption.dateAddedDesc:
            orderBy = 'created_at DESC';
            break;
          case FoodSortOption.quantityDesc:
            orderBy = 'remaining_quantity DESC';
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
      } else {
        items = items.where((i) => FoodCategory.isAllowedGrocery(i.category.name)).toList();
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
          final matchNotes = i.notes?.toLowerCase().contains(query) ?? false;
          final matchBarcode = i.barcode?.toLowerCase().contains(query) ?? false;
          return matchName || matchNotes || matchBarcode;
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
          items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          break;
        case FoodSortOption.expiryDateDesc:
          items.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
          break;
        case FoodSortOption.nameAsc:
          items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case FoodSortOption.dateAddedDesc:
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case FoodSortOption.quantityDesc:
          items.sort((a, b) => b.remainingQuantity.compareTo(a.remainingQuantity));
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
      if (!FoodCategory.isAllowedGrocery(item.category.name)) {
        throw ValidationException('Category ${item.category.label} is not a valid grocery category.');
      }
      final db = await _dbHelper.database;
      if (db != null) {
        await db.insert(
          AppConstants.foodTable,
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
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to insert food item: $e');
    }
  }

  @override
  Future<void> updateFoodItem(FoodItemModel item) async {
    try {
      if (!FoodCategory.isAllowedGrocery(item.category.name)) {
        throw ValidationException('Category ${item.category.label} is not a valid grocery category.');
      }
      final db = await _dbHelper.database;
      if (db != null) {
        final count = await db.update(
          AppConstants.foodTable,
          item.toMap(),
          where: 'id = ?',
          whereArgs: [item.id],
        );
        if (count == 0) {
          throw NotFoundException('Food item with id ${item.id} not found to update');
        }
      }

      final idx = _memoryStore.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        _memoryStore[idx] = item;
      } else if (db == null) {
        throw NotFoundException('Food item with id ${item.id} not found to update');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to update food item: $e');
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
      }
      _memoryStore.removeWhere((i) => i.id == id);
    } catch (e) {
      throw DatabaseException('Failed to delete food item: $e');
    }
  }

  @override
  Future<void> consumeFoodItem(String id, double consumedQuantity) async {
    try {
      final db = await _dbHelper.database;
      final item = await getFoodItemById(id);
      if (item == null) {
        throw NotFoundException('Food item with id $id not found');
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
      throw DatabaseException('Failed to consume food item: $e');
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
      throw DatabaseException('Failed to toggle favorite for food item: $e');
    }
  }

  @override
  Future<List<FoodItemModel>> getExpiringFoodItems({int warningDays = 2}) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final threshold = DateTime(now.year, now.month, now.day + warningDays, 23, 59, 59);

      if (db != null) {
        final groceryCats = FoodCategory.groceryCategoryNames;
        final placeholders = List.filled(groceryCats.length, '?').join(', ');

        final results = await db.query(
          AppConstants.foodTable,
          where: 'is_consumed = 0 AND expiry_date <= ? AND category IN ($placeholders)',
          whereArgs: [threshold.toIso8601String(), ...groceryCats],
          orderBy: 'expiry_date ASC',
        );

        return results.map((e) => FoodItemModel.fromMap(e)).toList();
      }

      return _memoryStore
          .where((i) =>
              !i.isConsumed &&
              FoodCategory.isAllowedGrocery(i.category.name) &&
              i.expiryDate.isBefore(threshold))
          .toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    } catch (e) {
      throw DatabaseException('Failed to query expiring food items: $e');
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

      final groceryCats = FoodCategory.groceryCategoryNames;

      int totalActive = 0;
      int expiringSoon = 0;
      int expiresToday = 0;
      int expired = 0;
      int fresh = 0;
      int totalConsumed = 0;

      if (db != null) {
        final placeholders = List.filled(groceryCats.length, '?').join(', ');

        final results = await db.query(
          AppConstants.foodTable,
          where: 'category IN ($placeholders)',
          whereArgs: groceryCats,
        );

        for (final row in results) {
          final isConsumed = (row['is_consumed'] as int? ?? 0) == 1;
          if (isConsumed) {
            totalConsumed++;
          } else {
            totalActive++;
            final expiryDate = DateTime.parse(row['expiry_date'] as String);
            final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
            final days = expiryDay.difference(today).inDays;

            if (days < 0) {
              expired++;
            } else if (days == 0) {
              expiresToday++;
            } else if (days <= warningDays) {
              expiringSoon++;
            } else {
              fresh++;
            }
          }
        }
      } else {
        if (!_seededInMemory && _memoryStore.isEmpty) {
          await seedSampleData();
        }

        for (final item in _memoryStore) {
          if (!FoodCategory.isAllowedGrocery(item.category.name)) continue;

          if (item.isConsumed) {
            totalConsumed++;
          } else {
            totalActive++;
            final expiryDate = item.expiryDate;
            final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
            final days = expiryDay.difference(today).inDays;

            if (days < 0) {
              expired++;
            } else if (days == 0) {
              expiresToday++;
            } else if (days <= warningDays) {
              expiringSoon++;
            } else {
              fresh++;
            }
          }
        }
      }

      return FoodStats(
        totalActive: totalActive,
        expiringSoon: expiringSoon,
        expiresToday: expiresToday,
        expired: expired,
        fresh: fresh,
        totalConsumed: totalConsumed,
      );
    } catch (e) {
      throw DatabaseException('Failed to calculate food stats: $e');
    }
  }

  @override
  Future<void> seedSampleData() async {
    try {
      final db = await _dbHelper.database;
      final groceryCats = FoodCategory.groceryCategoryNames;

      if (db != null) {
        final placeholders = List.filled(groceryCats.length, '?').join(', ');

        // 1. Quick check if valid grocery items already exist in the database
        final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppConstants.foodTable} WHERE category IN ($placeholders) LIMIT 1',
            groceryCats,
          ),
        );

        if (count != null && count > 0) return;

        // 2. If table is unseeded, purge legacy non-groceries and seed
        await db.delete(
          AppConstants.foodTable,
          where: 'category NOT IN ($placeholders)',
          whereArgs: groceryCats,
        );
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

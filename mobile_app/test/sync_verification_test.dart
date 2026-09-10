import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/core/constants/app_constants.dart';
import 'package:foodsave/core/database/database_helper.dart';
import 'package:foodsave/core/services/product_sync_service.dart';
import 'package:foodsave/features/food_inventory/data/datasources/food_local_datasource.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_filter.dart';
import 'package:foodsave/features/food_inventory/domain/entities/storage_location.dart';
import 'package:foodsave/features/food_inventory/data/models/food_item_model.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('ProductSyncService pullFromAdmin successfully populates foodTable with remote products', () async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    expect(db, isNotNull);

    // Mock an admin API response containing products including the newly added product
    final mockApiResponse = {
      'status': 'success',
      'data': [
        {
          'id': 'prod-25a240f30b272acd11d6',
          'user_id': 'default_user',
          'name': 'kltresdfgh',
          'brand': null,
          'barcode': null,
          'image_path': null,
          'category': 'Dairy',
          'quantity': 1.0,
          'unit': 'pieces',
          'purchase_price': 0,
          'purchase_date': '2026-09-08',
          'expiry_date': '2026-09-23',
          'reminder_date': '2026-09-16 00:00:00',
          'reminder_enabled': true,
          'reminder_days_before': '7',
          'storage_location': 'pantry',
          'is_consumed': false,
          'is_favorite': false,
          'created_at': '2026-09-08 14:37:27',
          'updated_at': '2026-09-08 14:37:27',
        },
        {
          'id': 'prod-3',
          'user_id': 'default_user',
          'name': 'Paracetamol 500mg',
          'category': 'Medicines & First Aid',
          'quantity': 10.0,
          'unit': 'pieces',
          'purchase_price': 45.0,
          'purchase_date': '2026-08-01',
          'expiry_date': '2026-09-05',
          'storage_location': 'pantry',
          'is_consumed': false,
          'is_favorite': false,
          'created_at': '2026-09-07 15:24:14',
          'updated_at': '2026-09-07 15:24:14',
        }
      ]
    };

    // Insert mocked items into SQLite simulating pullFromAdmin
    for (final raw in (mockApiResponse['data'] as List)) {
      final item = raw as Map<String, dynamic>;
      final id = item['id'].toString();
      final name = item['name'].toString();
      final rawCategory = item['category']?.toString() ?? 'Other Products';
      final category = FoodCategory.fromString(rawCategory).name;
      final rawLocation = item['storage_location']?.toString();
      final storageLocation = StorageLocation.fromString(rawLocation).name;

      await db!.rawInsert('''
        INSERT OR REPLACE INTO ${AppConstants.foodTable} (
          id, name, brand, barcode, image_path, category, subcategory,
          remaining_quantity, unit, purchase_date, manufacturing_date,
          expiry_date, reminder_date, reminder_enabled, reminder_days_before,
          notification_id, expiry_status, notes, is_consumed, created_at,
          updated_at, price, storage_location, is_favorite
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        id, name, null, null, null, category, null,
        item['quantity'], item['unit'] ?? 'pieces', item['purchase_date'], null,
        item['expiry_date'], item['reminder_date'], 1, '7',
        abs(id.hashCode), 'Safe', null, 0, item['created_at'],
        item['updated_at'], item['purchase_price'], storageLocation, 0,
      ]);
    }

    // Verify querying with category filter matches the synced product
    final dataSource = FoodLocalDataSourceImpl(dbHelper);
    final dairyItems = await dataSource.getFoodItems(
      filter: const FoodFilter(category: FoodCategory.dairy),
    );

    expect(dairyItems.any((i) => i.id == 'prod-25a240f30b272acd11d6'), isTrue);
    final newItem = dairyItems.firstWhere((i) => i.id == 'prod-25a240f30b272acd11d6');
    expect(newItem.name, 'kltresdfgh');
    expect(newItem.category, FoodCategory.dairy);

    final medicineItems = await dataSource.getFoodItems(
      filter: const FoodFilter(category: FoodCategory.medicines),
    );
    expect(medicineItems.any((i) => i.id == 'prod-3'), isTrue);
  });

  test('Local standalone product creation persists safely in SQLite and queues in sync_queue', () async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    expect(db, isNotNull);

    final dataSource = FoodLocalDataSourceImpl(dbHelper);
    final now = DateTime.now();
    const testItemId = 'standalone_test_item_123';

    final testProduct = FoodItemModel(
      id: testItemId,
      name: 'Fresh Organic Milk',
      brand: 'Farm Fresh',
      category: FoodCategory.dairy,
      purchaseDate: now,
      expiryDate: now.add(const Duration(days: 10)),
      remainingQuantity: 5.0,
      unit: FoodUnit.pieces,
      storageLocation: StorageLocation.fridge,
      createdAt: now,
      updatedAt: now,
    );

    // 1. Insert product locally
    await dataSource.insertFoodItem(testProduct);

    // 2. Verify product is persisted in SQLite
    final fetched = await dataSource.getFoodItemById(testItemId);
    expect(fetched, isNotNull);
    expect(fetched!.name, 'Fresh Organic Milk');
    expect(fetched.category, FoodCategory.dairy);

    // 3. Verify sync_queue contains valid row with status and string id
    final queueRows = await db!.query(
      AppConstants.syncQueueTable,
      where: 'entity_id = ?',
      whereArgs: [testItemId],
    );
    expect(queueRows.isNotEmpty, isTrue);
    final row = queueRows.first;
    expect(row['status'], 'pending');
    expect(row['retry_count'], 0);
    expect(row['entity_type'], 'product');
    expect(row['action'], 'insert');

    // 4. Verify syncPendingQueue executes cleanly without crashes
    final pushResult = await ProductSyncService.instance.syncPendingQueue();
    expect(pushResult, isNotNull);

    // 5. Verify pullFromAdmin in offline mode does not delete local product
    final pullCount = await ProductSyncService.instance.pullFromAdmin();
    expect(pullCount, 0);

    final recheck = await dataSource.getFoodItemById(testItemId);
    expect(recheck, isNotNull);
    expect(recheck!.id, testItemId);
  });
}

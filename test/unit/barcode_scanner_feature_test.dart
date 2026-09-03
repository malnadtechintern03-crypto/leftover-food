import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/core/database/database_helper.dart';
import 'package:foodsave/core/services/barcode_lookup_service.dart';
import 'package:foodsave/features/food_inventory/data/datasources/food_local_datasource.dart';
import 'package:foodsave/features/food_inventory/data/models/food_item_model.dart';
import 'package:foodsave/features/food_inventory/data/repositories/food_repository_impl.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_filter.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:foodsave/features/food_inventory/domain/entities/storage_location.dart';
import 'package:foodsave/features/food_inventory/domain/usecases/get_food_item_by_barcode_usecase.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;

void main() {
  final now = DateTime.now();

  group('Barcode Feature Unit Tests', () {
    late FoodLocalDataSource dataSource;
    late FoodRepositoryImpl repository;
    late GetFoodItemByBarcodeUseCase getFoodItemByBarcodeUseCase;

    setUp(() {
      dataSource = FoodLocalDataSourceImpl(MockDatabaseHelper());
      repository = FoodRepositoryImpl(dataSource);
      getFoodItemByBarcodeUseCase = GetFoodItemByBarcodeUseCase(repository);
    });

    test('BarcodeLookupService correctly resolves offline presets', () async {
      final lookupService = BarcodeLookupService.instance;

      final atta = await lookupService.lookupProduct('8906001020011');
      expect(atta, isNotNull);
      expect(atta!.name, 'Aashirvaad Superior MP Atta');
      expect(atta.category, FoodCategory.flourAndBaking);
      expect(atta.unit, FoodUnit.kg);

      final salt = await lookupService.lookupProduct('8901725181222');
      expect(salt, isNotNull);
      expect(salt!.name, 'Tata Salt Vacuum Evaporated');
      expect(salt.category, FoodCategory.spices);

      final ghee = await lookupService.lookupProduct('8901262010054');
      expect(ghee, isNotNull);
      expect(ghee!.name, 'Amul Pure Ghee Jar');
      expect(ghee.category, FoodCategory.oils);

      final unknown = await lookupService.lookupProduct('0000000000000');
      // When offline or uncatalogued, unknown barcode returns null for manual entry
      expect(unknown, isNull);
    });

    test('GetFoodItemByBarcodeUseCase finds active pantry grocery by barcode', () async {
      final item = FoodItem(
        id: 'item-barcode-123',
        name: 'Daawat Rozana Basmati Rice',
        category: FoodCategory.grainsAndPulses,
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 90)),
        remainingQuantity: 5,
        unit: FoodUnit.kg,
        storageLocation: StorageLocation.pantry,
        barcode: '8901030000000',
        createdAt: now,
        updatedAt: now,
      );

      await repository.addFoodItem(item);

      final found = await getFoodItemByBarcodeUseCase('8901030000000');
      expect(found, isNotNull);
      expect(found!.id, 'item-barcode-123');
      expect(found.name, 'Daawat Rozana Basmati Rice');
      expect(found.barcode, '8901030000000');

      final notFound = await getFoodItemByBarcodeUseCase('9999999999999');
      expect(notFound, isNull);
    });

    test('Search query matches barcode string', () async {
      final item = FoodItem(
        id: 'item-barcode-456',
        name: 'Fortune Sunflower Oil',
        category: FoodCategory.oils,
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 60)),
        remainingQuantity: 1,
        unit: FoodUnit.litre,
        storageLocation: StorageLocation.pantry,
        barcode: '8901233024040',
        createdAt: now,
        updatedAt: now,
      );

      await repository.addFoodItem(item);

      // Search by exact barcode
      final results1 = await repository.getFoodItems(
        filter: const FoodFilter(searchQuery: '8901233024040'),
      );
      expect(results1.any((i) => i.id == 'item-barcode-456'), isTrue);

      // Search by partial barcode
      final results2 = await repository.getFoodItems(
        filter: const FoodFilter(searchQuery: '3024040'),
      );
      expect(results2.any((i) => i.id == 'item-barcode-456'), isTrue);
    });

    test('FoodItemModel toMap and fromMap preserves barcode', () {
      final original = FoodItemModel(
        id: 'model-1',
        name: 'Tata Sampann Moong Dal',
        category: FoodCategory.grainsAndPulses,
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 120)),
        remainingQuantity: 2.0,
        unit: FoodUnit.kg,
        storageLocation: StorageLocation.pantry,
        price: 180.0,
        minimumStock: 1.0,
        barcode: '8901725134112',
        createdAt: now,
        updatedAt: now,
      );

      final map = original.toMap();
      expect(map['barcode'], '8901725134112');

      final deserialized = FoodItemModel.fromMap(map);
      expect(deserialized.barcode, '8901725134112');
      expect(deserialized.name, 'Tata Sampann Moong Dal');
    });
  });
}

class MockDatabaseHelper implements DatabaseHelper {
  @override
  Future<Database?> get database async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

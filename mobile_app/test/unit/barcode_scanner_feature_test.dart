import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/core/database/database_helper.dart';
import 'package:foodsave/core/services/barcode_lookup_service.dart';
import 'package:foodsave/core/utils/expiry_date_extractor.dart';
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

    test('BarcodeLookupService correctly resolves offline presets with image and expiry for any product', () async {
      final lookupService = BarcodeLookupService.instance;

      // 1. Grocery item
      final atta = await lookupService.lookupProduct('8906001020011');
      expect(atta, isNotNull);
      expect(atta!.name, 'Aashirvaad Superior MP Atta');
      expect(atta.category, FoodCategory.flourAndBaking);
      expect(atta.unit, FoodUnit.kg);
      expect(atta.effectiveImageUrl, isNotEmpty);
      expect(atta.estimatedExpiryDate.isAfter(DateTime.now()), isTrue);

      // 2. Medicine item (Dolo 650)
      final dolo = await lookupService.lookupProduct('8901117002010');
      expect(dolo, isNotNull);
      expect(dolo!.name, contains('Dolo 650'));
      expect(dolo.category, FoodCategory.medicines);
      expect(dolo.defaultShelfLifeDays, 730);
      expect(dolo.effectiveImageUrl, isNotEmpty);

      // 3. Personal Care (Dove Shampoo)
      final dove = await lookupService.lookupProduct('8901030612345');
      expect(dove, isNotNull);
      expect(dove!.name, contains('Dove'));
      expect(dove.category, FoodCategory.personalCare);
      expect(dove.defaultShelfLifeDays, 730);

      // 4. Household Cleaning (Surf Excel)
      final surf = await lookupService.lookupProduct('8901030700001');
      expect(surf, isNotNull);
      expect(surf!.name, contains('Surf Excel'));
      expect(surf.category, FoodCategory.householdCleaning);

      // 5. Electronics & Batteries (Duracell & Apple)
      final duracell = await lookupService.lookupProduct('5000394017771');
      expect(duracell, isNotNull);
      expect(duracell!.name, contains('Duracell'));
      expect(duracell.category, FoodCategory.electronicsAndHardware);
      expect(duracell.defaultShelfLifeDays, 1825);

      final appleAdapter = await lookupService.lookupProduct('194252031353');
      expect(appleAdapter, isNotNull);
      expect(appleAdapter!.name, contains('Apple 20W'));
      expect(appleAdapter.category, FoodCategory.electronicsAndHardware);
      expect(appleAdapter.brand, 'Apple');
      expect(appleAdapter.description, isNotNull);
      expect(appleAdapter.description, contains('USB-C'));

      // 6. Books / ISBN (Clean Code)
      final book = await lookupService.lookupProduct('9780132350884');
      expect(book, isNotNull);
      expect(book!.name, contains('Clean Code'));
      expect(book.category, FoodCategory.stationeryAndOffice);
      expect(book.brand, 'Robert C. Martin');
      expect(book.description, isNotNull);
      expect(book.description, contains('craftsmanship'));
      expect(book.storageLocation, StorageLocation.kitchenCabinet);
      expect(book.defaultShelfLifeDays, 3650);

      // 7. Stationery & Office (Post-it notes)
      final postIt = await lookupService.lookupProduct('051141920152');
      expect(postIt, isNotNull);
      expect(postIt!.name, contains('Post-it'));
      expect(postIt.category, FoodCategory.stationeryAndOffice);
      expect(postIt.description, isNotNull);

      // 8. Pet Supplies (Pedigree)
      final pedigree = await lookupService.lookupProduct('8906002480111');
      expect(pedigree, isNotNull);
      expect(pedigree!.name, contains('Pedigree'));
      expect(pedigree.category, FoodCategory.petSupplies);

      final unknown = await lookupService.lookupProduct('0000000000000');
      // When offline or uncatalogued, unknown barcode returns null for manual entry
      expect(unknown, isNull);
    });

    test('BarcodeLookupService smart fallback identifies GS1 origin and assigns logical defaults', () {
      // India origin
      final indiaFallback = BarcodeLookupService.createSmartFallbackProduct('8909999999999');
      expect(indiaFallback.name, contains('India'));
      expect(indiaFallback.storageLocation, StorageLocation.pantry);
      expect(indiaFallback.description, contains('India'));

      // Book / ISBN origin
      final isbnFallback = BarcodeLookupService.createSmartFallbackProduct('9781234567890');
      expect(isbnFallback.name, contains('Book (ISBN)'));
      expect(isbnFallback.category, FoodCategory.stationeryAndOffice);
      expect(isbnFallback.storageLocation, StorageLocation.kitchenCabinet);

      // US / Canada origin
      final usFallback = BarcodeLookupService.createSmartFallbackProduct('012345678905');
      expect(usFallback.name, contains('US / Canada'));

      // UK origin
      final ukFallback = BarcodeLookupService.createSmartFallbackProduct('5012345678901');
      expect(ukFallback.name, contains('United Kingdom'));
    });

    test('inferCategory and inferStorageLocation accurately classify non-grocery and grocery products', () {
      // Category inference
      expect(BarcodeLookupService.inferCategory('Harry Potter Paperback Novel Book'), FoodCategory.stationeryAndOffice);
      expect(BarcodeLookupService.inferCategory('Logitech Wireless Keyboard USB'), FoodCategory.electronicsAndHardware);
      expect(BarcodeLookupService.inferCategory('SanDisk Ultra 64GB Flash Drive'), FoodCategory.electronicsAndHardware);
      expect(BarcodeLookupService.inferCategory('Crocin Cold & Flu Paracetamol'), FoodCategory.medicines);
      expect(BarcodeLookupService.inferCategory('Colgate Total Whitening Toothpaste'), FoodCategory.personalCare);
      expect(BarcodeLookupService.inferCategory('Amul Taaza Homogenised Milk'), FoodCategory.dairy);

      // Storage location inference
      expect(BarcodeLookupService.inferStorageLocation(FoodCategory.dairy), StorageLocation.fridge);
      expect(BarcodeLookupService.inferStorageLocation(FoodCategory.medicines), StorageLocation.kitchenCabinet);
      expect(BarcodeLookupService.inferStorageLocation(FoodCategory.personalCare), StorageLocation.kitchenCabinet);
      expect(BarcodeLookupService.inferStorageLocation(FoodCategory.stationeryAndOffice), StorageLocation.kitchenCabinet);
      expect(BarcodeLookupService.inferStorageLocation(FoodCategory.electronicsAndHardware), StorageLocation.kitchenCabinet);
      expect(BarcodeLookupService.inferStorageLocation(FoodCategory.grainsAndPulses), StorageLocation.pantry);
      expect(BarcodeLookupService.inferStorageLocation(FoodCategory.householdCleaning), StorageLocation.pantry);
    });

    test('ExpiryDateExtractor correctly estimates shelf life and parses date text for any product', () {
      // Grocery
      final milkExpiry = ExpiryDateExtractor.estimateExpiryDate(
        category: FoodCategory.dairy,
        foodName: 'Fresh Whole Milk',
      );
      expect(milkExpiry.difference(DateTime.now()).inDays, inInclusiveRange(6, 8));

      // Medicine (2 years)
      final paracetamolExpiry = ExpiryDateExtractor.estimateExpiryDate(
        category: FoodCategory.medicines,
        foodName: 'Paracetamol 650mg Tablets',
      );
      expect(paracetamolExpiry.difference(DateTime.now()).inDays, inInclusiveRange(720, 735));

      // Cosmetics (1 year for sunscreen)
      final sunscreenExpiry = ExpiryDateExtractor.estimateExpiryDate(
        category: FoodCategory.personalCare,
        foodName: 'UV Sunscreen Lotion SPF 50',
      );
      expect(sunscreenExpiry.difference(DateTime.now()).inDays, inInclusiveRange(360, 370));

      // Batteries (5 years)
      final batteryExpiry = ExpiryDateExtractor.estimateExpiryDate(
        category: FoodCategory.electronicsAndHardware,
        foodName: 'Duracell AA Alkaline Batteries',
      );
      expect(batteryExpiry.difference(DateTime.now()).inDays, inInclusiveRange(1820, 1830));

      // Parsing formatted date strings across varied product packaging
      final d1 = ExpiryDateExtractor.parseExpiryDateText('EXP: 15/12/2026');
      expect(d1, isNotNull);
      expect(d1!.day, 15);
      expect(d1.month, 12);
      expect(d1.year, 2026);

      final d2 = ExpiryDateExtractor.parseExpiryDateText('Best Before 2027-08-20');
      expect(d2, isNotNull);
      expect(d2!.day, 20);
      expect(d2.month, 8);
      expect(d2.year, 2027);

      final d3 = ExpiryDateExtractor.parseExpiryDateText('10/26');
      expect(d3, isNotNull);
      expect(d3!.month, 10);
      expect(d3.year, 2026);

      final d4 = ExpiryDateExtractor.parseExpiryDateText('Batch No: 9942 Exp Date: 2029/03/15');
      expect(d4, isNotNull);
      expect(d4!.year, 2029);
      expect(d4.month, 3);
      expect(d4.day, 15);
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

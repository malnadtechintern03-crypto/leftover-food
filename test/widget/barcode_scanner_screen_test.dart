import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/app/theme/app_theme.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_filter.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_stats.dart';
import 'package:foodsave/features/food_inventory/domain/repositories/food_repository.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_inventory_providers.dart';
import 'package:foodsave/features/food_inventory/presentation/screens/add_edit_food_screen.dart';
import 'package:foodsave/features/food_inventory/presentation/screens/barcode_scanner_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class MockTestBarcodeFoodRepository implements FoodRepository {
  final List<FoodItem> items = [];

  @override
  Future<void> addFoodItem(FoodItem item) async => items.add(item);

  @override
  Future<void> clearAllData() async => items.clear();

  @override
  Future<void> consumeFoodItem(String id, double quantity) async {}

  @override
  Future<void> deleteFoodItem(String id) async => items.removeWhere((i) => i.id == id);

  @override
  Future<List<FoodItem>> getExpiringFoodItems({int warningDays = 2}) async => [];

  @override
  Future<FoodItem?> getFoodItemById(String id) async => items.where((i) => i.id == id).firstOrNull;

  @override
  Future<FoodItem?> getFoodItemByBarcode(String barcode) async =>
      items.where((i) => i.barcode == barcode && !i.isConsumed).firstOrNull;

  @override
  Future<List<FoodItem>> getFoodItems({FoodFilter? filter, int warningDays = 2}) async => items;

  @override
  Future<FoodStats> getFoodStats({int warningDays = 2}) async => const FoodStats();

  @override
  Future<List<FoodItem>> getLowStockItems() async => [];

  @override
  Future<List<FoodItem>> getRecurringGroceries() async => [];

  @override
  Future<void> seedInitialData() async {}

  @override
  Future<void> toggleFavorite(String id) async {}

  @override
  Future<void> updateFoodItem(FoodItem item) async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('BarcodeScannerScreen renders viewfinder reticle, instructions, and controls',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockTestBarcodeFoodRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BarcodeScannerScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title and Instructions
    expect(find.text('Scan Barcode'), findsOneWidget);
    expect(find.text('Place the grocery barcode inside the box'), findsOneWidget);

    // Verify Buttons
    expect(find.text('Enter Code'), findsWidgets);
    expect(find.text('Preset Catalog'), findsWidgets);

    // Tap "Enter Code" to open manual entry dialog
    await tester.tap(find.text('Enter Code').first);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Enter Barcode Manually'), findsOneWidget);
    expect(find.text('Barcode SKU'), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap "Preset Catalog" to open offline catalogue
    await tester.tap(find.text('Preset Catalog').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Offline Grocery Catalog'), findsOneWidget);
    expect(find.text('Aashirvaad Superior MP Atta'), findsOneWidget);
    expect(find.text('Tata Salt Vacuum Evaporated'), findsOneWidget);
  });

  testWidgets('AddEditFoodScreen renders prominent Scan Barcode button',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockTestBarcodeFoodRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AddEditFoodScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Scan Barcode button is present
    expect(find.text('📷 Scan Barcode'), findsOneWidget);
    expect(find.text('Grocery Item Name *'), findsOneWidget);
    expect(find.text('Grocery Category *'), findsOneWidget);
  });
}

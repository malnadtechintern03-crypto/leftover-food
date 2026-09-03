import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/app/theme/app_theme.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_detail_controller.dart';
import 'package:foodsave/features/food_inventory/presentation/screens/add_edit_food_screen.dart';
import 'package:foodsave/features/food_inventory/presentation/screens/food_detail_screen.dart';
import 'package:foodsave/features/food_inventory/presentation/widgets/consume_quantity_dialog.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_stats.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_filter.dart';
import 'package:foodsave/features/food_inventory/domain/repositories/food_repository.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_inventory_providers.dart';
import 'package:foodsave/features/settings/domain/entities/app_settings.dart';
import 'package:foodsave/features/settings/presentation/providers/settings_controller.dart';
import 'package:foodsave/features/settings/presentation/screens/settings_screen.dart';
import 'package:foodsave/features/settings/presentation/widgets/food_tips_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  final now = DateTime.now();
  final sampleItem = FoodItem(
    id: 'test-1',
    name: 'Basmati Rice',
    category: FoodCategory.grainsAndPulses,
    purchaseDate: now.subtract(const Duration(days: 1)),
    expiryDate: now.add(const Duration(days: 3)),
    remainingQuantity: 3,
    unit: FoodUnit.kg,
    notes: 'Aged rice in pantry jar',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('Test FoodTipsSheet with semantics enabled without parentData errors',
      (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: FoodTipsSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Grocery & Pantry Storage Tips'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Test SettingsScreen with semantics enabled without ListTile assertions',
      (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsControllerProvider.overrideWith((ref) => MockSettingsController()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Expiry & Notifications'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Test AddEditFoodScreen with semantics and preset chips',
      (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          foodRepositoryProvider.overrideWithValue(MockSemanticsFoodRepository(sampleItem)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AddEditFoodScreen(initialItem: sampleItem),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit Grocery Item'), findsOneWidget);
    expect(find.text('+3 Days'), findsOneWidget);
    expect(find.text('+1 Wk'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Test FoodDetailScreen with semantics enabled',
      (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          foodDetailControllerProvider('test-1').overrideWith(
            (ref) => MockFoodDetailController(sampleItem),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const FoodDetailScreen(id: 'test-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Basmati Rice'), findsOneWidget);
    expect(find.text('Remaining Quantity'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Test ConsumeQuantityDialog with semantics enabled',
      (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ConsumeQuantityDialog(item: sampleItem),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Log Food Used'), findsOneWidget);
    handle.dispose();
  });
}

class MockSettingsController extends StateNotifier<AsyncValue<AppSettings>>
    implements SettingsController {
  MockSettingsController()
      : super(const AsyncValue.data(AppSettings(
          themeMode: ThemeMode.system,
          expiryWarningDays: 2,
          notificationsEnabled: true,
          reminderHour: 9,
          reminderMinute: 0,
        )));

  @override
  Future<void> loadSettings() async {}

  @override
  Future<void> updateExpiryWarningDays(int days) async {
    state = AsyncValue.data(state.value!.copyWith(expiryWarningDays: days));
  }

  @override
  Future<void> updateNotificationsEnabled(bool enabled) async {
    state = AsyncValue.data(state.value!.copyWith(notificationsEnabled: enabled));
  }

  @override
  Future<void> updateReminderTime(TimeOfDay time) async {
    state = AsyncValue.data(state.value!.copyWith(
      reminderHour: time.hour,
      reminderMinute: time.minute,
    ));
  }

  @override
  Future<void> updateThemeMode(ThemeMode mode) async {
    state = AsyncValue.data(state.value!.copyWith(themeMode: mode));
  }
}

class MockFoodDetailController extends StateNotifier<AsyncValue<FoodItem?>>
    implements FoodDetailController {
  MockFoodDetailController(FoodItem item) : super(AsyncValue.data(item));

  @override
  String get id => 'test-1';

  @override
  Future<void> consume(double quantity) async {}

  @override
  Future<void> delete() async {}

  @override
  Future<void> extendExpiry(DateTime newExpiryDate) async {}

  @override
  Future<void> loadItem() async {}
}

class MockSemanticsFoodRepository implements FoodRepository {
  final FoodItem? item;
  MockSemanticsFoodRepository([this.item]);

  @override
  Future<void> addFoodItem(FoodItem item) async {}
  @override
  Future<void> clearAllData() async {}
  @override
  Future<void> consumeFoodItem(String id, double quantity) async {}
  @override
  Future<void> deleteFoodItem(String id) async {}
  @override
  Future<List<FoodItem>> getExpiringFoodItems({int warningDays = 2}) async => [];
  @override
  Future<FoodItem?> getFoodItemById(String id) async => item;
  @override
  Future<FoodItem?> getFoodItemByBarcode(String barcode) async => item?.barcode == barcode ? item : null;
  @override
  Future<List<FoodItem>> getFoodItems({FoodFilter? filter, int warningDays = 2}) async =>
      item != null ? [item!] : [];
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

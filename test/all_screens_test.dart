import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/app/theme/app_theme.dart';
import 'package:foodsave/core/widgets/confirmation_dialog.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_filter.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_stats.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:foodsave/features/food_inventory/domain/entities/storage_location.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_list_controller.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_stats_controller.dart';
import 'package:foodsave/features/food_inventory/presentation/screens/home_screen.dart';
import 'package:foodsave/features/settings/domain/entities/app_settings.dart';
import 'package:foodsave/features/settings/presentation/providers/settings_controller.dart';
import 'package:foodsave/features/settings/presentation/screens/notifications_center_screen.dart';
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

  testWidgets('Test HomeScreen rendering with mock controllers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          foodListControllerProvider.overrideWith((ref) => MockFoodListController([sampleItem])),
          foodStatsControllerProvider.overrideWith((ref) => MockFoodStatsController()),
          settingsControllerProvider.overrideWith((ref) => MockSettingsController()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Basmati Rice'), findsAtLeast(1));
    expect(find.text('All Grocery Items'), findsOneWidget);
  });

  testWidgets('Test NotificationsCenterScreen rendering', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          foodListControllerProvider.overrideWith((ref) => MockFoodListController([sampleItem])),
          settingsControllerProvider.overrideWith((ref) => MockSettingsController()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsCenterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(NotificationsCenterScreen), findsOneWidget);
  });

  testWidgets('Test ConfirmationDialog and EmptyStateView', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ConfirmationDialog(
            title: 'Delete Item',
            message: 'Are you sure?',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Delete Item'), findsOneWidget);
  });
}

class MockFoodListController extends StateNotifier<FoodListState>
    implements FoodListController {
  MockFoodListController(List<FoodItem> items)
      : super(FoodListState(
          items: AsyncValue.data(items),
          filter: const FoodFilter(),
          warningDays: 2,
        ));

  @override
  Future<void> consumeFood(String id, double quantity) async {}

  @override
  Future<void> deleteFood(String id) async {}

  @override
  Future<void> loadItems() async {}

  @override
  void setCategory(FoodCategory? category) {}

  @override
  void setSearchQuery(String query) {}

  @override
  void setSortOption(FoodSortOption sortOption) {}

  @override
  void setStatus(status) {}

  @override
  void setStorageLocation(StorageLocation? location) {}

  @override
  void setFavoriteOnly(bool? isFavorite) {}

  @override
  void setLowStockOnly(bool? isLowStock) {}

  @override
  Future<void> toggleFavorite(String id) async {}

  @override
  Future<void> quickAddFood({
    required String name,
    required double quantity,
    required DateTime expiryDate,
    FoodCategory category = FoodCategory.other,
    FoodUnit unit = FoodUnit.pieces,
    StorageLocation location = StorageLocation.pantry,
    double? price,
    double? minStock,
    String? barcode,
  }) async {}

  @override
  void toggleIncludeConsumed(bool include) {}

  @override
  void updateWarningDays(int days) {}

  @override
  Future<void> clearConsumedItems() async {}

  @override
  Future<void> resetDemoData() async {}

  @override
  Future<void> clearAllData() async {}
}

class MockFoodStatsController extends StateNotifier<AsyncValue<FoodStats>>
    implements FoodStatsController {
  MockFoodStatsController()
      : super(const AsyncValue.data(FoodStats(
          totalActive: 1,
          expiringSoon: 0,
          expired: 0,
          totalConsumed: 0,
        )));

  @override
  Future<void> loadStats() async {}

  @override
  void updateWarningDays(int days) {}
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
  Future<void> updateExpiryWarningDays(int days) async {}

  @override
  Future<void> updateNotificationsEnabled(bool enabled) async {}

  @override
  Future<void> updateReminderTime(TimeOfDay time) async {}

  @override
  Future<void> updateThemeMode(ThemeMode mode) async {}
}

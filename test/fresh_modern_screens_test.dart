import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foodsave/app/presentation/main_navigation_scaffold.dart';
import 'package:foodsave/app/theme/app_theme.dart';
import 'package:foodsave/features/expiry_calendar/presentation/providers/expiry_calendar_provider.dart';
import 'package:foodsave/features/expiry_calendar/presentation/screens/expiry_calendar_screen.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_filter.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_stats.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:foodsave/features/food_inventory/domain/entities/storage_location.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_list_controller.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_stats_controller.dart';
import 'package:foodsave/features/food_inventory/presentation/screens/pantry_screen.dart';
import 'package:foodsave/features/food_inventory/presentation/widgets/pantry_hero_card.dart';
import 'package:foodsave/features/food_inventory/presentation/widgets/status_metric_grid.dart';
import 'package:foodsave/features/profile/presentation/screens/profile_screen.dart';
import 'package:foodsave/features/recipes/presentation/screens/recipes_screen.dart';
import 'package:foodsave/features/settings/domain/entities/app_settings.dart';
import 'package:foodsave/features/settings/presentation/providers/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime.now();
  final sampleItems = [
    FoodItem(
      id: 'test-bread',
      name: 'Sourdough Bread',
      category: FoodCategory.flourAndBaking,
      purchaseDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.add(const Duration(hours: 4)),
      remainingQuantity: 1,
      unit: FoodUnit.pieces,
      notes: 'Bakery loaf',
      createdAt: now,
      updatedAt: now,
    ),
    FoodItem(
      id: 'test-milk',
      name: 'Milk',
      category: FoodCategory.dairy,
      purchaseDate: now.subtract(const Duration(days: 3)),
      expiryDate: now.add(const Duration(hours: 8)),
      remainingQuantity: 500,
      unit: FoodUnit.ml,
      notes: 'Whole milk',
      createdAt: now,
      updatedAt: now,
    ),
    FoodItem(
      id: 'test-yogurt',
      name: 'Greek Yogurt',
      category: FoodCategory.dairy,
      purchaseDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.add(const Duration(days: 1)),
      remainingQuantity: 250,
      unit: FoodUnit.grams,
      notes: 'Creamy yogurt',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  const sampleStats = FoodStats(
    totalActive: 18,
    expiringSoon: 4,
    expiresToday: 2,
    expired: 1,
    fresh: 11,
    totalConsumed: 7,
  );

  testWidgets('PantryHeroCard renders item count and Fresh gauge', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: PantryHeroCard(stats: sampleStats),
        ),
      ),
    );

    expect(find.text('18'), findsOneWidget);
    expect(find.text('Items in your pantry'), findsOneWidget);
    expect(find.text('Fresh'), findsOneWidget);
  });

  testWidgets('StatusMetricGrid renders 4 metric cards correctly', (WidgetTester tester) async {
    int? tappedIndex;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatusMetricGrid(
            stats: sampleStats,
            onCardTap: (idx) => tappedIndex = idx,
          ),
        ),
      ),
    );

    expect(find.text('Expiring Soon'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    expect(find.text('Expires Today'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    expect(find.text('Rescued'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    await tester.tap(find.text('Expiring Soon'));
    expect(tappedIndex, 1);
  });

  testWidgets('MainNavigationScaffold renders all 5 tabs including Calendar', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          foodListControllerProvider.overrideWith((ref) => MockTestFoodListController(sampleItems)),
          foodStatsControllerProvider.overrideWith((ref) => MockTestFoodStatsController(sampleStats)),
          settingsControllerProvider.overrideWith((ref) => MockTestSettingsController()),
          expiryCalendarControllerProvider.overrideWith((ref) => MockTestExpiryCalendarController(sampleItems)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScaffold(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Tab labels in Bottom Navigation Bar
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Recipes'), findsWidgets);
    expect(find.text('Profile'), findsOneWidget);

    // Switch to Groceries (Pantry) Tab
    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(find.byType(PantryScreen), findsOneWidget);

    // Switch to Calendar Tab
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ExpiryCalendarScreen), findsOneWidget);

    // Switch to Recipes Tab
    await tester.tap(find.byIcon(Icons.restaurant_menu_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesScreen), findsOneWidget);
    expect(find.text('Zero-Waste Recipe Match'), findsOneWidget);

    // Switch to Profile Tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Chef Kitchen'), findsOneWidget);
    expect(find.text('Zero-Waste Streak'), findsOneWidget);
  });
}

class MockTestFoodListController extends StateNotifier<FoodListState>
    implements FoodListController {
  MockTestFoodListController(List<FoodItem> items)
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

class MockTestFoodStatsController extends StateNotifier<AsyncValue<FoodStats>>
    implements FoodStatsController {
  MockTestFoodStatsController(FoodStats stats) : super(AsyncValue.data(stats));

  @override
  Future<void> loadStats() async {}

  @override
  void updateWarningDays(int days) {}
}

class MockTestSettingsController extends StateNotifier<AsyncValue<AppSettings>>
    implements SettingsController {
  MockTestSettingsController()
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

class MockTestExpiryCalendarController extends StateNotifier<ExpiryCalendarState>
    implements ExpiryCalendarController {
  MockTestExpiryCalendarController(List<FoodItem> items)
      : super(ExpiryCalendarState(
          selectedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
          selectedDate: DateTime.now(),
          viewMode: CalendarViewMode.month,
          items: AsyncValue.data(items),
          warningDays: 2,
        ));

  @override
  Future<void> loadEvents() async {}

  @override
  void selectDate(DateTime date) {}

  @override
  void setViewMode(CalendarViewMode mode) {}

  @override
  void goToToday() {}

  @override
  void previousMonth() {}

  @override
  void nextMonth() {}

  @override
  void updateWarningDays(int days) {}
}


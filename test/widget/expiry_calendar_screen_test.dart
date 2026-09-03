import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foodsave/app/theme/app_theme.dart';
import 'package:foodsave/features/expiry_calendar/presentation/screens/expiry_calendar_screen.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_inventory_providers.dart';
import 'package:foodsave/features/settings/domain/entities/app_settings.dart';
import 'package:foodsave/features/settings/presentation/providers/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/expiry_calendar_provider_test.dart';

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

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('ExpiryCalendarScreen renders monthly grid, controls and selected date list',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final sampleItems = [
      FoodItem(
        id: 'cal-item-1',
        name: 'Organic Whole Milk',
        category: FoodCategory.dairy,
        purchaseDate: now.subtract(const Duration(days: 2)),
        expiryDate: now,
        remainingQuantity: 1,
        unit: FoodUnit.litre,
        createdAt: now,
        updatedAt: now,
      ),
      FoodItem(
        id: 'cal-item-2',
        name: 'Artisan Bread',
        category: FoodCategory.flourAndBaking,
        purchaseDate: now.subtract(const Duration(days: 2)),
        expiryDate: now,
        remainingQuantity: 2,
        unit: FoodUnit.pieces,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final mockRepo = MockCalendarFoodRepository();
    mockRepo.mockItems = sampleItems;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          foodRepositoryProvider.overrideWithValue(mockRepo),
          settingsControllerProvider.overrideWith((ref) => MockTestSettingsController()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ExpiryCalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Expiry Calendar'), findsOneWidget);

    // Verify Controls
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);

    // Verify Days of Week
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);

    // Verify Today items listed in details panel
    expect(find.text('Organic Whole Milk'), findsOneWidget);
    expect(find.text('Artisan Bread'), findsOneWidget);

    // Switch to Week View
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('Organic Whole Milk'), findsOneWidget);

    // Switch to Day View
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text('Organic Whole Milk'), findsOneWidget);
  });
}

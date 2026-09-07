import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/app/theme/app_theme.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_filter.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_list_controller.dart';
import 'package:foodsave/features/recipes/presentation/screens/recipes_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class MockTestFoodListController extends StateNotifier<FoodListState>
    implements FoodListController {
  MockTestFoodListController()
      : super(const FoodListState(
          items: AsyncValue.data([]),
          filter: FoodFilter(),
          warningDays: 2,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('RecipesScreen renders YouTube video badges and buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodListControllerProvider.overrideWith((ref) => MockTestFoodListController()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RecipesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and banner
    expect(find.text('Smart Recipes'), findsOneWidget);
    expect(find.text('Zero-Waste Recipe Match'), findsOneWidget);

    // Verify recipe cards render
    expect(find.text('Aromatic Tadka Dal & Basmati Rice'), findsOneWidget);
    expect(find.text('Artisan Toasted Sourdough with Olive Oil'), findsOneWidget);

    // Verify YouTube badges and Watch on YouTube buttons exist
    expect(find.text('YouTube Video'), findsWidgets);
    expect(find.text('Watch on YouTube'), findsWidgets);
    expect(find.text('Steps'), findsWidgets);

    // Tap "Steps" to open bottom sheet
    await tester.tap(find.text('Steps').first);
    await tester.pumpAndSettle();

    // Verify bottom sheet has "Watch Video Tutorial on YouTube" button
    expect(find.text('Watch Video Tutorial on YouTube'), findsOneWidget);
    expect(find.text('Required Ingredients'), findsOneWidget);
    expect(find.text('Step-by-Step Instructions'), findsOneWidget);
  });
}

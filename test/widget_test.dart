import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foodsave/app/theme/app_theme.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:foodsave/features/food_inventory/presentation/widgets/food_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('FoodCard renders food name, quantity and expiry badge', (WidgetTester tester) async {
    final now = DateTime.now();
    final item = FoodItem(
      id: 'test-1',
      name: 'Basmati Rice',
      category: FoodCategory.grainsAndPulses,
      purchaseDate: now.subtract(const Duration(days: 1)),
      expiryDate: now.add(const Duration(days: 3)),
      remainingQuantity: 3,
      unit: FoodUnit.kg,
      notes: 'Premium aged grains',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: FoodCard(
              item: item,
              warningDays: 2,
              onTap: () {},
              onConsume: (_) {},
            ),
          ),
        ),
      ),
    );

    // Verify Name
    expect(find.text('Basmati Rice'), findsOneWidget);

    // Verify Category
    expect(find.text('Grains & Pulses'), findsOneWidget);

    // Verify Quantity
    expect(find.textContaining('3 kg'), findsOneWidget);

    // Verify Expiry status badge
    expect(find.text('3 days left'), findsOneWidget);

    // Verify Three-Dot Menu
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
  });
}

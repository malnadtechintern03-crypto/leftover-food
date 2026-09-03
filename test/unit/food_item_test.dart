import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_status.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';

void main() {
  group('FoodItem Entity Tests', () {
    final now = DateTime(2026, 8, 29, 12, 0);

    test('Status should be Fresh when expiry is 5 days away', () {
      final item = FoodItem(
        id: '1',
        name: 'Whole Wheat Flour',
        category: FoodCategory.flourAndBaking,
        purchaseDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 5)),
        remainingQuantity: 1,
        unit: FoodUnit.kg,
        createdAt: now,
        updatedAt: now,
      );

      expect(item.getStatus(warningDays: 2, referenceDate: now), FoodStatus.fresh);
      expect(item.isExpired(referenceDate: now), false);
      expect(item.isExpiringSoon(warningDays: 2, referenceDate: now), false);
      expect(item.daysUntilExpiry(referenceDate: now), 5);
    });

    test('Status should be Expiring Soon when expiry is within warning threshold (<= 2 days)', () {
      final item = FoodItem(
        id: '2',
        name: 'Sourdough Bread',
        category: FoodCategory.flourAndBaking,
        purchaseDate: now.subtract(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 1)),
        remainingQuantity: 1,
        unit: FoodUnit.pieces,
        createdAt: now,
        updatedAt: now,
      );

      expect(item.getStatus(warningDays: 2, referenceDate: now), FoodStatus.expiringSoon);
      expect(item.isExpired(referenceDate: now), false);
      expect(item.isExpiringSoon(warningDays: 2, referenceDate: now), true);
      expect(item.daysUntilExpiry(referenceDate: now), 1);
    });

    test('Status should be Expired when expiry date has passed', () {
      final item = FoodItem(
        id: '3',
        name: 'Old Milk',
        category: FoodCategory.dairy,
        purchaseDate: now.subtract(const Duration(days: 7)),
        expiryDate: now.subtract(const Duration(days: 1)),
        remainingQuantity: 1,
        unit: FoodUnit.litre,
        createdAt: now,
        updatedAt: now,
      );

      expect(item.getStatus(warningDays: 2, referenceDate: now), FoodStatus.expired);
      expect(item.isExpired(referenceDate: now), true);
    });

    test('Status should be Consumed when isConsumed is true or remainingQuantity is 0', () {
      final item = FoodItem(
        id: '4',
        name: 'Finished Biscuits',
        category: FoodCategory.snacksAndPackaged,
        purchaseDate: now.subtract(const Duration(days: 3)),
        expiryDate: now.add(const Duration(days: 2)),
        remainingQuantity: 0,
        unit: FoodUnit.grams,
        isConsumed: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(item.getStatus(warningDays: 2, referenceDate: now), FoodStatus.consumed);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/core/utils/expiry_calculator.dart';

void main() {
  group('ExpiryCalculator Tests', () {
    final refDate = DateTime(2026, 8, 29, 10, 0);

    test('daysRemaining calculates correctly', () {
      final tomorrow = DateTime(2026, 8, 30, 10, 0);
      final inThreeDays = DateTime(2026, 9, 1, 10, 0);
      final yesterday = DateTime(2026, 8, 28, 10, 0);

      expect(ExpiryCalculator.daysRemaining(tomorrow, referenceDate: refDate), 1);
      expect(ExpiryCalculator.daysRemaining(inThreeDays, referenceDate: refDate), 3);
      expect(ExpiryCalculator.daysRemaining(yesterday, referenceDate: refDate), -1);
    });

    test('getExpiryStatusText formats accurately', () {
      final today = DateTime(2026, 8, 29, 20, 0);
      final tomorrow = DateTime(2026, 8, 30, 10, 0);
      final inFiveDays = DateTime(2026, 9, 3, 10, 0);
      final yesterday = DateTime(2026, 8, 28, 10, 0);
      final threeDaysAgo = DateTime(2026, 8, 26, 10, 0);

      expect(ExpiryCalculator.getExpiryStatusText(today, referenceDate: refDate), 'Expires today');
      expect(ExpiryCalculator.getExpiryStatusText(tomorrow, referenceDate: refDate), 'Expires tomorrow');
      expect(ExpiryCalculator.getExpiryStatusText(inFiveDays, referenceDate: refDate), '5 days left');
      expect(ExpiryCalculator.getExpiryStatusText(yesterday, referenceDate: refDate), 'Expired yesterday');
      expect(ExpiryCalculator.getExpiryStatusText(threeDaysAgo, referenceDate: refDate), 'Expired 3 days ago');
    });

    test('calculateFreshnessProgress calculates normalized ratios', () {
      final purchase = DateTime(2026, 8, 25);
      final expiry = DateTime(2026, 8, 30);
      final current = DateTime(2026, 8, 27, 12, 0);

      final progress = ExpiryCalculator.calculateFreshnessProgress(
        purchaseDate: purchase,
        expiryDate: expiry,
        referenceDate: current,
      );

      expect(progress, greaterThan(0.0));
      expect(progress, lessThan(1.0));
      expect(progress, closeTo(0.5, 0.1));
    });
  });
}

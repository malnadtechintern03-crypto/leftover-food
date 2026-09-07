/// Helper class for calculating expiry metrics and countdown texts
class ExpiryCalculator {
  ExpiryCalculator._();

  /// Calculates integer calendar days remaining until [expiryDate] compared to [referenceDate] (defaults to now)
  static int daysRemaining(DateTime? expiryDate, {DateTime? referenceDate}) {
    if (expiryDate == null) return 999999;
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return target.difference(today).inDays;
  }

  /// Calculates total days food has been kept since [purchaseDate]
  static int daysStored(DateTime purchaseDate, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day);
    final diff = today.difference(target).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Returns user-friendly countdown or status string
  static String getExpiryStatusText(DateTime? expiryDate, {DateTime? referenceDate, bool useFullExpiresIn = false}) {
    if (expiryDate == null) return 'No Expiry Date';
    final days = daysRemaining(expiryDate, referenceDate: referenceDate);
    if (days < 0) {
      final absDays = days.abs();
      return absDays == 1 ? 'Expired yesterday' : 'Expired $absDays days ago';
    }
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (useFullExpiresIn) return 'Expires in $days days';
    return '$days days left';
  }

  /// Returns exact wording required by spec:
  /// - “Expires in 30 days”
  /// - “Expires in 7 days”
  /// - “Expires tomorrow”
  /// - “Expires today”
  /// - “Expired 3 days ago”
  static String formatRemainingTime(DateTime? expiryDate, {DateTime? referenceDate}) {
    return getExpiryStatusText(expiryDate, referenceDate: referenceDate, useFullExpiresIn: true);
  }

  /// Returns a progress ratio (0.0 to 1.0) indicating shelf-life consumed
  static double calculateFreshnessProgress({
    required DateTime purchaseDate,
    required DateTime? expiryDate,
    DateTime? referenceDate,
  }) {
    if (expiryDate == null) return 0.0;
    final now = referenceDate ?? DateTime.now();
    final totalSpan = expiryDate.difference(purchaseDate).inSeconds;
    if (totalSpan <= 0) return 1.0;

    final elapsed = now.difference(purchaseDate).inSeconds;
    if (elapsed <= 0) return 0.0;
    if (elapsed >= totalSpan) return 1.0;

    return elapsed / totalSpan;
  }
}

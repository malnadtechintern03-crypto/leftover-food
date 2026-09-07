/// Aggregate statistics for the dashboard and expiration monitoring
class FoodStats {
  final int totalActive;
  final int expiringSoon;
  final int expiresToday;
  final int expiringWithin7Days;
  final int expiringWithin30Days;
  final int expired;
  final int noExpiryDate;
  final int fresh;
  final int totalConsumed;

  const FoodStats({
    this.totalActive = 0,
    this.expiringSoon = 0,
    this.expiresToday = 0,
    this.expiringWithin7Days = 0,
    this.expiringWithin30Days = 0,
    this.expired = 0,
    this.noExpiryDate = 0,
    this.fresh = 0,
    this.totalConsumed = 0,
  });

  int get totalProducts => totalActive;
  int get safe => fresh;

  /// Wastage prevention rate percentage (0 - 100)
  double get wasteSavedPercentage {
    final finished = totalConsumed + expired;
    if (finished == 0) return 100.0;
    return (totalConsumed / finished) * 100.0;
  }

  /// Fresh pantry health score percentage (0 - 100)
  int get freshPercentage {
    if (totalActive == 0) return 100;
    final urgentCount = expiringSoon + expiresToday + expired;
    final healthyFresh = (totalActive - urgentCount).clamp(0, totalActive);
    return ((healthyFresh / totalActive) * 100).round();
  }
}


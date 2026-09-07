import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../food_inventory/domain/entities/food_filter.dart';
import '../../../food_inventory/presentation/providers/food_inventory_providers.dart';

class BudgetState {
  final double monthlyLimit;
  final double totalSpentThisMonth;

  const BudgetState({
    this.monthlyLimit = AppConstants.defaultMonthlyBudgetINR,
    this.totalSpentThisMonth = 0.0,
  });

  double get remainingBudget => (monthlyLimit - totalSpentThisMonth).clamp(0.0, double.infinity);
  double get spentPercentage => monthlyLimit > 0 ? (totalSpentThisMonth / monthlyLimit).clamp(0.0, 1.5) : 0.0;
  bool get isOverBudget => totalSpentThisMonth > monthlyLimit;

  BudgetState copyWith({
    double? monthlyLimit,
    double? totalSpentThisMonth,
  }) {
    return BudgetState(
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      totalSpentThisMonth: totalSpentThisMonth ?? this.totalSpentThisMonth,
    );
  }
}

class BudgetController extends StateNotifier<BudgetState> {
  final Ref _ref;

  BudgetController(this._ref) : super(const BudgetState()) {
    loadBudget();
  }

  Future<void> loadBudget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final limit = prefs.getDouble(AppConstants.budgetMonthlyLimitKey) ??
          AppConstants.defaultMonthlyBudgetINR;

      // Calculate spent this month from food inventory
      final repo = _ref.read(foodRepositoryProvider);
      final allItems = await repo.getFoodItems(
        filter: const FoodFilter(includeConsumed: true),
      );

      final now = DateTime.now();
      double spent = 0.0;
      for (final item in allItems) {
        if (item.purchaseDate.year == now.year &&
            item.purchaseDate.month == now.month) {
          spent += (item.price ?? 0.0);
        }
      }

      state = BudgetState(monthlyLimit: limit, totalSpentThisMonth: spent);
    } catch (_) {}
  }

  Future<void> setMonthlyLimit(double limit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(AppConstants.budgetMonthlyLimitKey, limit);
      state = state.copyWith(monthlyLimit: limit);
    } catch (_) {}
  }
}

final budgetControllerProvider =
    StateNotifierProvider<BudgetController, BudgetState>((ref) {
  return BudgetController(ref);
});

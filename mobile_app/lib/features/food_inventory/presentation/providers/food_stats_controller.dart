import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/food_stats.dart';
import '../../domain/usecases/get_food_stats_usecase.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import 'food_inventory_providers.dart';

class FoodStatsController extends StateNotifier<AsyncValue<FoodStats>> {
  final GetFoodStatsUseCase _getStatsUseCase;
  int _warningDays;

  FoodStatsController(
    this._getStatsUseCase,
    int initialWarningDays,
  )   : _warningDays = initialWarningDays,
        super(const AsyncValue.loading()) {
    loadStats();
  }

  void updateWarningDays(int days) {
    if (_warningDays != days) {
      _warningDays = days;
      loadStats();
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _getStatsUseCase(warningDays: _warningDays);
      if (!mounted) return;
      state = AsyncValue.data(stats);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }
}

final foodStatsControllerProvider =
    StateNotifierProvider<FoodStatsController, AsyncValue<FoodStats>>((ref) {
  final getStats = ref.watch(getFoodStatsUseCaseProvider);
  final warningDays = ref.watch(
    settingsControllerProvider.select((s) => s.valueOrNull?.expiryWarningDays ?? 2),
  );

  return FoodStatsController(
    getStats,
    warningDays,
  );
});

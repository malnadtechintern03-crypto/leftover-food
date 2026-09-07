import '../entities/food_stats.dart';
import '../repositories/food_repository.dart';

class GetFoodStatsUseCase {
  final FoodRepository _repository;

  const GetFoodStatsUseCase(this._repository);

  Future<FoodStats> call({int warningDays = 2}) async {
    return await _repository.getFoodStats(warningDays: warningDays);
  }
}

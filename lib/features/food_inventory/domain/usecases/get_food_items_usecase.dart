import '../entities/food_filter.dart';
import '../entities/food_item.dart';
import '../repositories/food_repository.dart';

class GetFoodItemsUseCase {
  final FoodRepository _repository;

  const GetFoodItemsUseCase(this._repository);

  Future<List<FoodItem>> call({
    FoodFilter? filter,
    int warningDays = 2,
  }) async {
    return await _repository.getFoodItems(
      filter: filter,
      warningDays: warningDays,
    );
  }
}

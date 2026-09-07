import '../entities/food_item.dart';
import '../repositories/food_repository.dart';

class GetExpiringFoodItemsUseCase {
  final FoodRepository _repository;

  const GetExpiringFoodItemsUseCase(this._repository);

  Future<List<FoodItem>> call({int warningDays = 2}) async {
    return await _repository.getExpiringFoodItems(warningDays: warningDays);
  }
}

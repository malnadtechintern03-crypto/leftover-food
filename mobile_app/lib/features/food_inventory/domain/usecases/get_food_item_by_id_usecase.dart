import '../entities/food_item.dart';
import '../repositories/food_repository.dart';

class GetFoodItemByIdUseCase {
  final FoodRepository _repository;

  const GetFoodItemByIdUseCase(this._repository);

  Future<FoodItem?> call(String id) async {
    return await _repository.getFoodItemById(id);
  }
}

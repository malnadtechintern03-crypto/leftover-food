import '../repositories/food_repository.dart';

class DeleteFoodItemUseCase {
  final FoodRepository _repository;

  const DeleteFoodItemUseCase(this._repository);

  Future<void> call(String id) async {
    await _repository.deleteFoodItem(id);
  }
}

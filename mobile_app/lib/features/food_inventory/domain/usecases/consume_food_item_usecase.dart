import '../../../../core/errors/failure.dart';
import '../repositories/food_repository.dart';

class ConsumeFoodItemUseCase {
  final FoodRepository _repository;

  const ConsumeFoodItemUseCase(this._repository);

  Future<void> call(String id, double consumedQuantity) async {
    if (consumedQuantity <= 0) {
      throw const ValidationFailure('Consumed quantity must be greater than zero.');
    }
    await _repository.consumeFoodItem(id, consumedQuantity);
  }
}

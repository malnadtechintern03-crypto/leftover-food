import '../../../../core/errors/failure.dart';
import '../entities/food_item.dart';
import '../repositories/food_repository.dart';

class AddFoodItemUseCase {
  final FoodRepository _repository;

  const AddFoodItemUseCase(this._repository);

  Future<void> call(FoodItem item) async {
    if (item.name.trim().isEmpty) {
      throw const ValidationFailure('Food name cannot be empty.');
    }
    if (item.remainingQuantity <= 0) {
      throw const ValidationFailure('Quantity must be greater than zero.');
    }
    if (item.expiryDate.isBefore(
      DateTime(item.purchaseDate.year, item.purchaseDate.month, item.purchaseDate.day),
    )) {
      throw const ValidationFailure('Expiry date cannot be before cooked/purchase date.');
    }

    await _repository.addFoodItem(item);
  }
}

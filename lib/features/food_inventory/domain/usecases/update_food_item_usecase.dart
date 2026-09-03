import '../../../../core/errors/failure.dart';
import '../entities/food_item.dart';
import '../repositories/food_repository.dart';

class UpdateFoodItemUseCase {
  final FoodRepository _repository;

  const UpdateFoodItemUseCase(this._repository);

  Future<void> call(FoodItem item) async {
    if (item.name.trim().isEmpty) {
      throw const ValidationFailure('Food name cannot be empty.');
    }
    if (item.remainingQuantity < 0) {
      throw const ValidationFailure('Quantity cannot be negative.');
    }
    if (item.expiryDate.isBefore(
      DateTime(item.purchaseDate.year, item.purchaseDate.month, item.purchaseDate.day),
    )) {
      throw const ValidationFailure('Expiry date cannot be before cooked/purchase date.');
    }

    await _repository.updateFoodItem(item);
  }
}

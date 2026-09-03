import '../entities/food_item.dart';
import '../repositories/food_repository.dart';

class GetFoodItemByBarcodeUseCase {
  final FoodRepository _repository;

  const GetFoodItemByBarcodeUseCase(this._repository);

  Future<FoodItem?> call(String barcode) async {
    return await _repository.getFoodItemByBarcode(barcode);
  }
}

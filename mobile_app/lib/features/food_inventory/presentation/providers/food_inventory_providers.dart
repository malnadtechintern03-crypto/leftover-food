import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/datasources/food_local_datasource.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/usecases/add_food_item_usecase.dart';
import '../../domain/usecases/consume_food_item_usecase.dart';
import '../../domain/usecases/delete_food_item_usecase.dart';
import '../../domain/usecases/get_expiring_food_items_usecase.dart';
import '../../domain/usecases/get_food_item_by_barcode_usecase.dart';
import '../../domain/usecases/get_food_item_by_id_usecase.dart';
import '../../domain/usecases/get_food_items_usecase.dart';
import '../../domain/usecases/get_food_stats_usecase.dart';
import '../../domain/usecases/update_food_item_usecase.dart';

/// DatabaseHelper provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Food local data source provider
final foodLocalDataSourceProvider = Provider<FoodLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return FoodLocalDataSourceImpl(dbHelper);
});

/// Food repository provider
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final dataSource = ref.watch(foodLocalDataSourceProvider);
  return FoodRepositoryImpl(dataSource);
});

/// Use Case Providers
final getFoodItemsUseCaseProvider = Provider<GetFoodItemsUseCase>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return GetFoodItemsUseCase(repository);
});

final getFoodItemByIdUseCaseProvider = Provider<GetFoodItemByIdUseCase>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return GetFoodItemByIdUseCase(repository);
});

final getFoodItemByBarcodeUseCaseProvider = Provider<GetFoodItemByBarcodeUseCase>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return GetFoodItemByBarcodeUseCase(repository);
});

final addFoodItemUseCaseProvider = Provider<AddFoodItemUseCase>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return AddFoodItemUseCase(repository);
});

final updateFoodItemUseCaseProvider = Provider<UpdateFoodItemUseCase>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return UpdateFoodItemUseCase(repository);
});

final deleteFoodItemUseCaseProvider = Provider<DeleteFoodItemUseCase>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return DeleteFoodItemUseCase(repository);
});

final consumeFoodItemUseCaseProvider = Provider<ConsumeFoodItemUseCase>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return ConsumeFoodItemUseCase(repository);
});

final getExpiringFoodItemsUseCaseProvider = Provider<GetExpiringFoodItemsUseCase>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return GetExpiringFoodItemsUseCase(repository);
});

final getFoodStatsUseCaseProvider = Provider<GetFoodStatsUseCase>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return GetFoodStatsUseCase(repository);
});

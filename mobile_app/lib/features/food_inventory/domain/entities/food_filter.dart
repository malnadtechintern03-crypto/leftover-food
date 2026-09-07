import 'food_category.dart';
import 'food_status.dart';
import 'storage_location.dart';

enum FoodSortOption {
  expiryDateAsc('Expiry Date (Soonest first)'),
  expiryDateDesc('Expiry Date (Latest first)'),
  dateAddedDesc('Date Added (Newest first)'),
  dateAddedAsc('Date Added (Oldest first)'),
  nameAsc('Product Name (A-Z)'),
  nameDesc('Product Name (Z-A)'),
  quantityDesc('Quantity (High to Low)'),
  quantityAsc('Quantity (Low to High)'),
  categoryAsc('Category (A-Z)');

  final String label;
  const FoodSortOption(this.label);
}

/// Filter and sort criteria for grocery queries
class FoodFilter {
  final String searchQuery;
  final FoodCategory? category;
  final FoodStatus? status;
  final StorageLocation? storageLocation;
  final bool? isFavorite;
  final bool? isLowStock;
  final FoodSortOption sortOption;
  final bool includeConsumed;

  const FoodFilter({
    this.searchQuery = '',
    this.category,
    this.status,
    this.storageLocation,
    this.isFavorite,
    this.isLowStock,
    this.sortOption = FoodSortOption.expiryDateAsc,
    this.includeConsumed = false,
  });

  FoodFilter copyWith({
    String? searchQuery,
    FoodCategory? category,
    bool clearCategory = false,
    FoodStatus? status,
    bool clearStatus = false,
    StorageLocation? storageLocation,
    bool clearStorageLocation = false,
    bool? isFavorite,
    bool clearIsFavorite = false,
    bool? isLowStock,
    bool clearIsLowStock = false,
    FoodSortOption? sortOption,
    bool? includeConsumed,
  }) {
    return FoodFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      status: clearStatus ? null : (status ?? this.status),
      storageLocation: clearStorageLocation
          ? null
          : (storageLocation ?? this.storageLocation),
      isFavorite: clearIsFavorite ? null : (isFavorite ?? this.isFavorite),
      isLowStock: clearIsLowStock ? null : (isLowStock ?? this.isLowStock),
      sortOption: sortOption ?? this.sortOption,
      includeConsumed: includeConsumed ?? this.includeConsumed,
    );
  }

  bool get hasActiveFilter =>
      searchQuery.trim().isNotEmpty ||
      category != null ||
      status != null ||
      storageLocation != null ||
      isFavorite != null ||
      isLowStock != null;
}

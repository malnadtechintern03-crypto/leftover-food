import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../features/food_inventory/domain/entities/food_category.dart';
import '../../features/food_inventory/domain/entities/food_unit.dart';
import '../../features/food_inventory/domain/entities/storage_location.dart';

class BarcodeProduct {
  final String barcode;
  final String name;
  final FoodCategory category;
  final double defaultQuantity;
  final FoodUnit unit;
  final StorageLocation storageLocation;
  final double? defaultPrice;
  final double? minimumStock;
  final int defaultShelfLifeDays;
  final String? brand;
  final String? imageUrl;

  const BarcodeProduct({
    required this.barcode,
    required this.name,
    required this.category,
    required this.defaultQuantity,
    required this.unit,
    required this.storageLocation,
    this.defaultPrice,
    this.minimumStock,
    this.defaultShelfLifeDays = 30,
    this.brand,
    this.imageUrl,
  });
}

/// Offline preset catalog of standard grocery items
final List<BarcodeProduct> offlineBarcodeCatalog = [
  const BarcodeProduct(
    barcode: '8906001020011',
    name: 'Aashirvaad Superior MP Atta',
    category: FoodCategory.flourAndBaking,
    defaultQuantity: 5.0,
    unit: FoodUnit.kg,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 245.0,
    minimumStock: 2.0,
    defaultShelfLifeDays: 90,
    brand: 'Aashirvaad',
  ),
  const BarcodeProduct(
    barcode: '8901725181222',
    name: 'Tata Salt Vacuum Evaporated',
    category: FoodCategory.spices,
    defaultQuantity: 1.0,
    unit: FoodUnit.kg,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 28.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 730,
    brand: 'Tata',
  ),
  const BarcodeProduct(
    barcode: '8901262010054',
    name: 'Amul Pure Ghee Jar',
    category: FoodCategory.oils,
    defaultQuantity: 500.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 340.0,
    minimumStock: 200.0,
    defaultShelfLifeDays: 180,
    brand: 'Amul',
  ),
  const BarcodeProduct(
    barcode: '8901030000000',
    name: 'Daawat Rozana Basmati Rice',
    category: FoodCategory.grainsAndPulses,
    defaultQuantity: 5.0,
    unit: FoodUnit.kg,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 380.0,
    minimumStock: 2.0,
    defaultShelfLifeDays: 180,
    brand: 'Daawat',
  ),
  const BarcodeProduct(
    barcode: '8901233024040',
    name: 'Fortune Sunlite Sunflower Oil',
    category: FoodCategory.oils,
    defaultQuantity: 1.0,
    unit: FoodUnit.litre,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 175.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 180,
    brand: 'Fortune',
  ),
  const BarcodeProduct(
    barcode: '8901058852355',
    name: 'Maggi 2-Minute Masala Noodles',
    category: FoodCategory.snacksAndPackaged,
    defaultQuantity: 4.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 56.0,
    minimumStock: 2.0,
    defaultShelfLifeDays: 120,
    brand: 'Nestle',
  ),
  const BarcodeProduct(
    barcode: '8901030383808',
    name: 'Kissan Mixed Fruit Jam',
    category: FoodCategory.other,
    defaultQuantity: 500.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.fridge,
    defaultPrice: 155.0,
    minimumStock: 150.0,
    defaultShelfLifeDays: 180,
    brand: 'Kissan',
  ),
  const BarcodeProduct(
    barcode: '8901030825315',
    name: 'Bru Instant Coffee Powder',
    category: FoodCategory.beverages,
    defaultQuantity: 200.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 220.0,
    minimumStock: 50.0,
    defaultShelfLifeDays: 180,
    brand: 'Bru',
  ),
  const BarcodeProduct(
    barcode: '8901030864314',
    name: 'Taj Mahal Premium Tea',
    category: FoodCategory.beverages,
    defaultQuantity: 500.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 320.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 180,
    brand: 'Taj Mahal',
  ),
  const BarcodeProduct(
    barcode: '8901262020015',
    name: 'Amul Pasteurised Butter',
    category: FoodCategory.dairy,
    defaultQuantity: 500.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.fridge,
    defaultPrice: 275.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 90,
    brand: 'Amul',
  ),
  const BarcodeProduct(
    barcode: '8901262015011',
    name: 'Amul Taaza Homogenised Toned Milk',
    category: FoodCategory.dairy,
    defaultQuantity: 1.0,
    unit: FoodUnit.litre,
    storageLocation: StorageLocation.fridge,
    defaultPrice: 72.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 90,
    brand: 'Amul',
  ),
  const BarcodeProduct(
    barcode: '8901063012111',
    name: 'Britannia Good Day Butter Cookies',
    category: FoodCategory.snacksAndPackaged,
    defaultQuantity: 200.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 40.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 180,
    brand: 'Britannia',
  ),
  const BarcodeProduct(
    barcode: '8901725134105',
    name: 'Tata Sampann Unpolished Toor Dal',
    category: FoodCategory.grainsAndPulses,
    defaultQuantity: 1.0,
    unit: FoodUnit.kg,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 185.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 365,
    brand: 'Tata Sampann',
  ),
  const BarcodeProduct(
    barcode: '8901725134112',
    name: 'Tata Sampann Unpolished Moong Dal',
    category: FoodCategory.grainsAndPulses,
    defaultQuantity: 1.0,
    unit: FoodUnit.kg,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 160.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 365,
    brand: 'Tata Sampann',
  ),
  const BarcodeProduct(
    barcode: '8901499008888',
    name: 'Everest Turmeric Powder',
    category: FoodCategory.spices,
    defaultQuantity: 200.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 65.0,
    minimumStock: 50.0,
    defaultShelfLifeDays: 365,
    brand: 'Everest',
  ),
  const BarcodeProduct(
    barcode: '8901499009999',
    name: 'Everest Garam Masala',
    category: FoodCategory.spices,
    defaultQuantity: 100.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 82.0,
    minimumStock: 30.0,
    defaultShelfLifeDays: 365,
    brand: 'Everest',
  ),
  const BarcodeProduct(
    barcode: '8904004400123',
    name: 'Patanjali Pure Cow Ghee',
    category: FoodCategory.oils,
    defaultQuantity: 1.0,
    unit: FoodUnit.litre,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 620.0,
    minimumStock: 0.5,
    defaultShelfLifeDays: 270,
    brand: 'Patanjali',
  ),
  const BarcodeProduct(
    barcode: '8901030012345',
    name: 'Quaker Rolled White Oats',
    category: FoodCategory.grainsAndPulses,
    defaultQuantity: 1.0,
    unit: FoodUnit.kg,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 190.0,
    minimumStock: 0.5,
    defaultShelfLifeDays: 180,
    brand: 'Quaker',
  ),
  const BarcodeProduct(
    barcode: '8901262030021',
    name: 'Amul Malai Paneer Block',
    category: FoodCategory.dairy,
    defaultQuantity: 200.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.fridge,
    defaultPrice: 90.0,
    minimumStock: 200.0,
    defaultShelfLifeDays: 45,
    brand: 'Amul',
  ),
  const BarcodeProduct(
    barcode: '8901262040013',
    name: 'Amul Processed Cheese Cubes',
    category: FoodCategory.dairy,
    defaultQuantity: 200.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.fridge,
    defaultPrice: 135.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 180,
    brand: 'Amul',
  ),
];

/// Service for identifying grocery products from barcodes offline and online
class BarcodeLookupService {
  static final BarcodeLookupService instance = BarcodeLookupService._();
  BarcodeLookupService._();

  /// Looks up product info for a given barcode.
  /// First checks the local offline catalog.
  /// If not found and device has connectivity, optionally queries public Open Food Facts.
  Future<BarcodeProduct?> lookupProduct(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    // 1. Check local offline catalog
    final localMatch = offlineBarcodeCatalog.firstWhere(
      (p) => p.barcode == cleanBarcode,
      orElse: () => const BarcodeProduct(
        barcode: '',
        name: '',
        category: FoodCategory.other,
        defaultQuantity: 1.0,
        unit: FoodUnit.pieces,
        storageLocation: StorageLocation.pantry,
      ),
    );

    if (localMatch.barcode.isNotEmpty) {
      return localMatch;
    }

    // 2. Safe Open Food Facts lookup with short timeout
    if (!kIsWeb) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
        final request = await client.getUrl(
          Uri.parse('https://world.openfoodfacts.org/api/v0/product/$cleanBarcode.json'),
        ).timeout(const Duration(seconds: 2));
        final response = await request.close().timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          if (data['status'] == 1 && data['product'] != null) {
            final prod = data['product'] as Map<String, dynamic>;
            final productName = (prod['product_name'] as String?)?.trim() ??
                (prod['generic_name'] as String?)?.trim() ??
                'Grocery Item ($cleanBarcode)';
            final brand = (prod['brands'] as String?)?.trim();

            // Infer category
            final categoriesTags = (prod['categories_tags'] as List<dynamic>?)
                    ?.map((e) => e.toString().toLowerCase())
                    .toList() ??
                [];
            FoodCategory category = FoodCategory.other;
            StorageLocation location = StorageLocation.pantry;

            if (categoriesTags.any((t) => t.contains('dairy') || t.contains('milk') || t.contains('cheese') || t.contains('yogurt'))) {
              category = FoodCategory.dairy;
              location = StorageLocation.fridge;
            } else if (categoriesTags.any((t) => t.contains('flour') || t.contains('baking') || t.contains('bread'))) {
              category = FoodCategory.flourAndBaking;
            } else if (categoriesTags.any((t) => t.contains('cereal') || t.contains('grain') || t.contains('rice') || t.contains('pulse') || t.contains('legume') || t.contains('lentil'))) {
              category = FoodCategory.grainsAndPulses;
            } else if (categoriesTags.any((t) => t.contains('spice') || t.contains('condiment') || t.contains('salt') || t.contains('sauce'))) {
              category = FoodCategory.spices;
              location = StorageLocation.kitchenCabinet;
            } else if (categoriesTags.any((t) => t.contains('oil') || t.contains('fat') || t.contains('ghee'))) {
              category = FoodCategory.oils;
            } else if (categoriesTags.any((t) => t.contains('snack') || t.contains('biscuit') || t.contains('noodle') || t.contains('sweet'))) {
              category = FoodCategory.snacksAndPackaged;
            } else if (categoriesTags.any((t) => t.contains('beverage') || t.contains('tea') || t.contains('coffee') || t.contains('drink'))) {
              category = FoodCategory.beverages;
            }

            final imageUrl = prod['image_front_small_url'] as String? ?? prod['image_url'] as String?;

            return BarcodeProduct(
              barcode: cleanBarcode,
              name: brand != null && !productName.toLowerCase().contains(brand.toLowerCase())
                  ? '$brand $productName'
                  : productName,
              category: category,
              defaultQuantity: 1.0,
              unit: FoodUnit.pieces,
              storageLocation: location,
              defaultShelfLifeDays: 60,
              brand: brand,
              imageUrl: imageUrl,
            );
          }
        }
      } catch (e) {
        debugPrint('Barcode lookup offline fallback note: $e');
      }
    }

    return null;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../features/food_inventory/domain/entities/food_category.dart';
import '../../features/food_inventory/domain/entities/food_unit.dart';
import '../../features/food_inventory/domain/entities/storage_location.dart';
import '../utils/expiry_date_extractor.dart';
import '../utils/food_image_helper.dart';

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
    this.defaultShelfLifeDays = 365,
    this.brand,
    this.imageUrl,
  });

  /// Automatically computes the smart expiry date from today
  DateTime get estimatedExpiryDate => ExpiryDateExtractor.estimateExpiryDate(
        category: category,
        foodName: name,
        customShelfLifeDays: defaultShelfLifeDays,
      );

  /// Returns the effective product image (API direct image or curated high-res photo)
  String get effectiveImageUrl =>
      (imageUrl != null && imageUrl!.trim().isNotEmpty)
          ? imageUrl!
          : FoodImageHelper.getEffectiveImageUrl(name, category);
}

/// Offline preset catalog of standard products across groceries, medicines, cosmetics, household, pet & electronics
final List<BarcodeProduct> offlineBarcodeCatalog = [
  // 🌾 Groceries, Grains & Staples (Common presets)
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
    imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
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
    imageUrl: 'https://images.unsplash.com/photo-1518110925495-5fe2fda0442c?auto=format&fit=crop&w=400&q=80',
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
    imageUrl: 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&w=400&q=80',
  ),

  // 💊 Medicines & Pharmaceuticals
  const BarcodeProduct(
    barcode: '8901117002010',
    name: 'Dolo 650 Paracetamol Tablets',
    category: FoodCategory.medicines,
    defaultQuantity: 15.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 32.0,
    minimumStock: 5.0,
    defaultShelfLifeDays: 730,
    brand: 'Micro Labs',
    imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901396001004',
    name: 'Dettol Antiseptic Disinfectant Liquid',
    category: FoodCategory.medicines,
    defaultQuantity: 250.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 145.0,
    minimumStock: 50.0,
    defaultShelfLifeDays: 730,
    brand: 'Reckitt Benckiser',
    imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901117002027',
    name: 'Crocin Advance Paracetamol 500mg',
    category: FoodCategory.medicines,
    defaultQuantity: 20.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 24.0,
    minimumStock: 5.0,
    defaultShelfLifeDays: 730,
    brand: 'GSK',
    imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901117002034',
    name: 'Vicks VapoRub Relief Balm',
    category: FoodCategory.medicines,
    defaultQuantity: 50.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 160.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 730,
    brand: 'Procter & Gamble',
    imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
  ),

  // 🧴 Personal Care & Beauty
  const BarcodeProduct(
    barcode: '8901030612345',
    name: 'Dove Daily Shine Shampoo',
    category: FoodCategory.personalCare,
    defaultQuantity: 340.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 280.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 730,
    brand: 'Dove',
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '4005808246328',
    name: 'Nivea Nourishing Body Milk Lotion',
    category: FoodCategory.personalCare,
    defaultQuantity: 400.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 360.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 730,
    brand: 'Nivea',
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901314010521',
    name: 'Colgate Total 12H Antibacterial Toothpaste',
    category: FoodCategory.personalCare,
    defaultQuantity: 150.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 135.0,
    minimumStock: 50.0,
    defaultShelfLifeDays: 730,
    brand: 'Colgate',
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901030700025',
    name: 'Pears Pure & Gentle Bathing Soap',
    category: FoodCategory.personalCare,
    defaultQuantity: 125.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 65.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 730,
    brand: 'Pears',
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
  ),

  // 🧹 Cleaning & Household
  const BarcodeProduct(
    barcode: '8901030700001',
    name: 'Surf Excel Matic Front Load Detergent Liquid',
    category: FoodCategory.householdCleaning,
    defaultQuantity: 1.0,
    unit: FoodUnit.litre,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 240.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 730,
    brand: 'Surf Excel',
    imageUrl: 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901396321003',
    name: 'Lizol Citrus Floor Cleaner Disinfectant',
    category: FoodCategory.householdCleaning,
    defaultQuantity: 500.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 110.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 730,
    brand: 'Lizol',
    imageUrl: 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901030800000',
    name: 'Vim Lemon Dishwash Gel',
    category: FoodCategory.householdCleaning,
    defaultQuantity: 500.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 115.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 730,
    brand: 'Vim',
    imageUrl: 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901396321010',
    name: 'Harpic Power Plus Toilet Cleaner Liquid',
    category: FoodCategory.householdCleaning,
    defaultQuantity: 500.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 95.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 730,
    brand: 'Harpic',
    imageUrl: 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
  ),

  // 🐶 Pet Care
  const BarcodeProduct(
    barcode: '8906002480111',
    name: 'Pedigree Adult Meat & Rice Dog Food',
    category: FoodCategory.petSupplies,
    defaultQuantity: 3.0,
    unit: FoodUnit.kg,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 650.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 365,
    brand: 'Pedigree',
    imageUrl: 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8906002480128',
    name: 'Whiskas Adult Ocean Fish Cat Food',
    category: FoodCategory.petSupplies,
    defaultQuantity: 1.2,
    unit: FoodUnit.kg,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 380.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 365,
    brand: 'Whiskas',
    imageUrl: 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?auto=format&fit=crop&w=400&q=80',
  ),

  // 👶 Baby Care
  const BarcodeProduct(
    barcode: '8901012111000',
    name: 'Johnson Baby Powder with Natural Cornstarch',
    category: FoodCategory.babyCare,
    defaultQuantity: 200.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 160.0,
    minimumStock: 50.0,
    defaultShelfLifeDays: 730,
    brand: 'Johnson & Johnson',
    imageUrl: 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '4902430752100',
    name: 'Pampers All Round Protection Baby Diapers',
    category: FoodCategory.babyCare,
    defaultQuantity: 32.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 499.0,
    minimumStock: 5.0,
    defaultShelfLifeDays: 1095,
    brand: 'Pampers',
    imageUrl: 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80',
  ),

  // 🔋 Electronics & Hardware
  const BarcodeProduct(
    barcode: '5000394017771',
    name: 'Duracell Chhota Power Alkaline AA Batteries',
    category: FoodCategory.electronicsAndHardware,
    defaultQuantity: 4.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 160.0,
    minimumStock: 2.0,
    defaultShelfLifeDays: 1825,
    brand: 'Duracell',
    imageUrl: 'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901860010010',
    name: 'Fevicol All-Fix Clear Adhesive Glue',
    category: FoodCategory.stationeryAndOffice,
    defaultQuantity: 50.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 45.0,
    minimumStock: 10.0,
    defaultShelfLifeDays: 540,
    brand: 'Pidilite',
    imageUrl: 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=400&q=80',
  ),

  // 🌾 Groceries, Grains & Pantry
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
    imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
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
    imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
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
    imageUrl: 'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=400&q=80',
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
    imageUrl: 'https://images.unsplash.com/photo-1584473457406-624048518851?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901030825315',
    name: 'Bru Instant Coffee Powder',
    category: FoodCategory.beverages,
    defaultQuantity: 200.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 195.0,
    minimumStock: 50.0,
    defaultShelfLifeDays: 180,
    brand: 'Bru',
    imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901491101838',
    name: 'Kurkure Masala Munch Crispy Snacks',
    category: FoodCategory.snacksAndPackaged,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 20.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 120,
    brand: 'Kurkure',
    imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901725134112',
    name: 'Tata Sampann Unpolished Toor Dal',
    category: FoodCategory.grainsAndPulses,
    defaultQuantity: 1.0,
    unit: FoodUnit.kg,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 175.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 180,
    brand: 'Tata Sampann',
    imageUrl: 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',
  ),
  const BarcodeProduct(
    barcode: '8901030360854',
    name: 'Lipton Pure & Light Green Tea Bags',
    category: FoodCategory.beverages,
    defaultQuantity: 25.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 165.0,
    minimumStock: 10.0,
    defaultShelfLifeDays: 180,
    brand: 'Lipton',
    imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=400&q=80',
  ),
];

/// Service for looking up barcodes across offline catalog and multi-source online databases (Food, Beauty, General Merchandise, and UPCitemdb)
class BarcodeLookupService {
  static final BarcodeLookupService instance = BarcodeLookupService._();
  BarcodeLookupService._();

  /// Map for fast offline lookup
  final Map<String, BarcodeProduct> _offlineIndex = {
    for (var p in offlineBarcodeCatalog) p.barcode: p,
  };

  /// Infer product category from text keywords
  static FoodCategory inferCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('medicine') ||
        lower.contains('pharma') ||
        lower.contains('tablet') ||
        lower.contains('capsule') ||
        lower.contains('syrup') ||
        lower.contains('paracetamol') ||
        lower.contains('crocin') ||
        lower.contains('dolo') ||
        lower.contains('first aid') ||
        lower.contains('antiseptic') ||
        lower.contains('dettol') ||
        lower.contains('savlon') ||
        lower.contains('vitamin') ||
        lower.contains('balm') ||
        lower.contains('ointment') ||
        lower.contains('drops')) {
      return FoodCategory.medicines;
    } else if (lower.contains('beauty') ||
        lower.contains('cosmetic') ||
        lower.contains('shampoo') ||
        lower.contains('conditioner') ||
        lower.contains('lotion') ||
        lower.contains('cream') ||
        lower.contains('skin') ||
        lower.contains('sunscreen') ||
        lower.contains('toothpaste') ||
        lower.contains('colgate') ||
        lower.contains('soap') ||
        lower.contains('body wash') ||
        lower.contains('perfume') ||
        lower.contains('deodorant') ||
        lower.contains('face wash')) {
      return FoodCategory.personalCare;
    } else if (lower.contains('clean') ||
        lower.contains('detergent') ||
        lower.contains('surf') ||
        lower.contains('wash') ||
        lower.contains('disinfectant') ||
        lower.contains('bleach') ||
        lower.contains('floor') ||
        lower.contains('toilet') ||
        lower.contains('dishwash') ||
        lower.contains('vim') ||
        lower.contains('pril') ||
        lower.contains('lizol') ||
        lower.contains('harpic')) {
      return FoodCategory.householdCleaning;
    } else if (lower.contains('pet') ||
        lower.contains('dog') ||
        lower.contains('cat') ||
        lower.contains('pedigree') ||
        lower.contains('whiskas') ||
        lower.contains('drools')) {
      return FoodCategory.petSupplies;
    } else if (lower.contains('baby') ||
        lower.contains('diaper') ||
        lower.contains('infant') ||
        lower.contains('pampers') ||
        lower.contains('huggies') ||
        lower.contains('cerelac')) {
      return FoodCategory.babyCare;
    } else if (lower.contains('battery') ||
        lower.contains('duracell') ||
        lower.contains('energizer') ||
        lower.contains('cell') ||
        lower.contains('electronic') ||
        lower.contains('hardware') ||
        lower.contains('cable') ||
        lower.contains('charger')) {
      return FoodCategory.electronicsAndHardware;
    } else if (lower.contains('stationery') ||
        lower.contains('office') ||
        lower.contains('glue') ||
        lower.contains('fevicol') ||
        lower.contains('adhesive') ||
        lower.contains('pen') ||
        lower.contains('pencil') ||
        lower.contains('tape') ||
        lower.contains('paper')) {
      return FoodCategory.stationeryAndOffice;
    } else if (lower.contains('dairy') ||
        lower.contains('milk') ||
        lower.contains('cheese') ||
        lower.contains('yogurt') ||
        lower.contains('curd') ||
        lower.contains('paneer') ||
        lower.contains('butter')) {
      return FoodCategory.dairy;
    } else if (lower.contains('flour') ||
        lower.contains('baking') ||
        lower.contains('bread') ||
        lower.contains('atta') ||
        lower.contains('maida')) {
      return FoodCategory.flourAndBaking;
    } else if (lower.contains('cereal') ||
        lower.contains('grain') ||
        lower.contains('rice') ||
        lower.contains('pulse') ||
        lower.contains('dal') ||
        lower.contains('lentil')) {
      return FoodCategory.grainsAndPulses;
    } else if (lower.contains('spice') ||
        lower.contains('salt') ||
        lower.contains('pepper') ||
        lower.contains('masala') ||
        lower.contains('sauce')) {
      return FoodCategory.spices;
    } else if (lower.contains('oil') ||
        lower.contains('ghee') ||
        lower.contains('olive')) {
      return FoodCategory.oils;
    } else if (lower.contains('snack') ||
        lower.contains('biscuit') ||
        lower.contains('cookie') ||
        lower.contains('noodle') ||
        lower.contains('chip') ||
        lower.contains('chocolate')) {
      return FoodCategory.snacksAndPackaged;
    } else if (lower.contains('beverage') ||
        lower.contains('tea') ||
        lower.contains('coffee') ||
        lower.contains('drink') ||
        lower.contains('juice') ||
        lower.contains('soda')) {
      return FoodCategory.beverages;
    }
    return FoodCategory.other;
  }

  /// Looks up a product by its barcode from offline presets or multi-database online queries
  Future<BarcodeProduct?> lookupProduct(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty || cleanBarcode.replaceAll('0', '').isEmpty) return null;

    // 1. Check local catalog first
    if (_offlineIndex.containsKey(cleanBarcode)) {
      return _offlineIndex[cleanBarcode];
    }

    // Try finding by standard 12-digit UPC to 13-digit EAN variations
    final localMatch = _offlineIndex.values.firstWhere(
      (p) => (cleanBarcode.length == 12 && p.barcode == '0$cleanBarcode') ||
             (p.barcode.length == 12 && cleanBarcode == '0${p.barcode}'),
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

    // 2. Multi-Source Online Lookup: Open Food Facts, Open Beauty Facts, Open Products Facts & UPCitemdb in parallel
    if (!kIsWeb) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);

      // Query 1: Open Food Facts / Beauty / Products Facts
      final openFactsUrls = [
        'https://world.openfoodfacts.org/api/v0/product/$cleanBarcode.json',
        'https://world.openbeautyfacts.org/api/v0/product/$cleanBarcode.json',
        'https://world.openproductsfacts.org/api/v0/product/$cleanBarcode.json',
      ];

      final openFactsFutures = openFactsUrls.map((url) async {
        try {
          final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 4));
          request.headers.set('User-Agent', 'HomePantryApp/1.0.0 (Android; support@homepantry.com)');
          final response = await request.close().timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final responseBody = await response.transform(utf8.decoder).join();
            final data = jsonDecode(responseBody) as Map<String, dynamic>;
            if (data['status'] == 1 && data['product'] != null) {
              final prod = data['product'] as Map<String, dynamic>;
              final productName = (prod['product_name'] as String?)?.trim() ??
                  (prod['generic_name'] as String?)?.trim();
              final brand = (prod['brands'] as String?)?.trim();
              final categoriesTags = (prod['categories_tags'] as List<dynamic>?)
                      ?.map((e) => e.toString().toLowerCase())
                      .toList() ??
                  [];

              final directImage = prod['image_front_url'] as String? ??
                  prod['image_front_small_url'] as String? ??
                  prod['image_url'] as String?;

              if (productName != null && productName.isNotEmpty) {
                final combinedText = '$productName ${categoriesTags.join(' ')} ${brand ?? ''}';
                final category = inferCategory(combinedText);
                final displayName = brand != null && !productName.toLowerCase().contains(brand.toLowerCase())
                    ? '$brand $productName'
                    : productName;

                final shelfLife = ExpiryDateExtractor.categoryShelfLifeDays[category] ?? 365;
                final effectiveImage = directImage ?? FoodImageHelper.getEffectiveImageUrl(displayName, category);

                return BarcodeProduct(
                  barcode: cleanBarcode,
                  name: displayName,
                  category: category,
                  defaultQuantity: 1.0,
                  unit: FoodUnit.pieces,
                  storageLocation: category == FoodCategory.dairy ? StorageLocation.fridge : StorageLocation.pantry,
                  defaultShelfLifeDays: shelfLife,
                  brand: brand,
                  imageUrl: effectiveImage,
                );
              }
            }
          }
        } catch (_) {}
        return null;
      });

      // Query 2: UPCitemdb (universal commercial retail products catalog)
      Future<BarcodeProduct?> queryUpcItemDb() async {
        try {
          final upcUrl = 'https://api.upcitemdb.com/prod/trial/lookup?upc=$cleanBarcode';
          final request = await client.getUrl(Uri.parse(upcUrl)).timeout(const Duration(seconds: 4));
          request.headers.set('User-Agent', 'HomePantryApp/1.0.0 (Android; support@homepantry.com)');
          final response = await request.close().timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final responseBody = await response.transform(utf8.decoder).join();
            final data = jsonDecode(responseBody) as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>?;
            if (items != null && items.isNotEmpty) {
              final item = items.first as Map<String, dynamic>;
              final title = (item['title'] as String?)?.trim();
              final brand = (item['brand'] as String?)?.trim();
              final images = (item['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

              if (title != null && title.isNotEmpty) {
                final category = inferCategory('$title ${item['category'] ?? ''} ${brand ?? ''}');
                final shelfLife = ExpiryDateExtractor.categoryShelfLifeDays[category] ?? 365;
                final effectiveImage = images.isNotEmpty
                    ? images.first
                    : FoodImageHelper.getEffectiveImageUrl(title, category);

                return BarcodeProduct(
                  barcode: cleanBarcode,
                  name: title,
                  category: category,
                  defaultQuantity: 1.0,
                  unit: FoodUnit.pieces,
                  storageLocation: StorageLocation.pantry,
                  defaultShelfLifeDays: shelfLife,
                  brand: brand,
                  imageUrl: effectiveImage,
                );
              }
            }
          }
        } catch (_) {}
        return null;
      }

      // Execute all lookups concurrently
      final allFutures = [...openFactsFutures, queryUpcItemDb()];
      final results = await Future.wait(allFutures);
      for (final res in results) {
        if (res != null) return res;
      }
    }

    // 3. Fallback: If not found in any database, return null
    return null;
  }

  /// Creates a helpful smart fallback product when a barcode is not in public databases
  static BarcodeProduct createSmartFallbackProduct(String barcode) {
    FoodCategory category = FoodCategory.other;
    String suggestedPrefix = '';

    if (barcode.startsWith('890')) {
      suggestedPrefix = 'Item (India)';
    } else if (barcode.startsWith('500') || barcode.startsWith('501') || barcode.startsWith('502') || barcode.startsWith('503')) {
      suggestedPrefix = 'Item (UK)';
    } else if (barcode.startsWith('0') || barcode.startsWith('1')) {
      suggestedPrefix = 'Item (US/CA)';
    } else if (barcode.startsWith('40') || barcode.startsWith('41') || barcode.startsWith('42') || barcode.startsWith('43') || barcode.startsWith('44')) {
      suggestedPrefix = 'Item (Germany)';
    } else if (barcode.startsWith('690') || barcode.startsWith('691') || barcode.startsWith('692')) {
      suggestedPrefix = 'Item (China)';
    }

    final name = suggestedPrefix.isNotEmpty ? '$suggestedPrefix SKU $barcode' : 'Scanned Product ($barcode)';
    final shelfLife = ExpiryDateExtractor.categoryShelfLifeDays[category] ?? 365;

    return BarcodeProduct(
      barcode: barcode,
      name: name,
      category: category,
      defaultQuantity: 1.0,
      unit: FoodUnit.pieces,
      storageLocation: StorageLocation.pantry,
      defaultShelfLifeDays: shelfLife,
      imageUrl: FoodImageHelper.getEffectiveImageUrl(name, category),
    );
  }
}

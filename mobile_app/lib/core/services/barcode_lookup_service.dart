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
  final String? description;
  final String? packageSize;

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
    this.description,
    this.packageSize,
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
    barcode: '8901058000269',
    name: 'Maggi 2-Minute Masala Noodles',
    category: FoodCategory.snacksAndPackaged,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 14.0,
    minimumStock: 2.0,
    defaultShelfLifeDays: 180,
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

  // 📚 Books & Technical Publications
  const BarcodeProduct(
    barcode: '9780132350884',
    name: 'Clean Code: A Handbook of Agile Software Craftsmanship',
    category: FoodCategory.stationeryAndOffice,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 799.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 3650,
    brand: 'Robert C. Martin',
    imageUrl: 'https://images.unsplash.com/photo-1532012164546-f432f2e3777a?auto=format&fit=crop&w=400&q=80',
    description: 'A handbook of agile software craftsmanship. Master the principles, patterns, and practices of writing clean, maintainable code.',
  ),
  const BarcodeProduct(
    barcode: '9780131103627',
    name: 'The C Programming Language (2nd Edition)',
    category: FoodCategory.stationeryAndOffice,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 599.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 3650,
    brand: 'Brian W. Kernighan & Dennis M. Ritchie',
    imageUrl: 'https://images.unsplash.com/photo-1532012164546-f432f2e3777a?auto=format&fit=crop&w=400&q=80',
    description: 'The definitive classic reference work on the C programming language by its designers.',
  ),
  const BarcodeProduct(
    barcode: '9780201616224',
    name: 'The Pragmatic Programmer: Your Journey To Mastery',
    category: FoodCategory.stationeryAndOffice,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 850.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 3650,
    brand: 'David Thomas & Andrew Hunt',
    imageUrl: 'https://images.unsplash.com/photo-1532012164546-f432f2e3777a?auto=format&fit=crop&w=400&q=80',
    description: 'Illustrates the best approaches and major pitfalls of modern software development for pragmatic practitioners.',
  ),
  const BarcodeProduct(
    barcode: '9780439708180',
    name: "Harry Potter and the Sorcerer's Stone",
    category: FoodCategory.stationeryAndOffice,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 499.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 3650,
    brand: 'J.K. Rowling',
    imageUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=400&q=80',
    description: "The international bestselling fantasy novel introducing Harry Potter and Hogwarts School of Witchcraft and Wizardry.",
  ),

  // 🔋 Electronics & Hardware Accessories
  const BarcodeProduct(
    barcode: '194252031353',
    name: 'Apple 20W USB-C Power Adapter',
    category: FoodCategory.electronicsAndHardware,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 1900.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 1825,
    brand: 'Apple',
    imageUrl: 'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?auto=format&fit=crop&w=400&q=80',
    description: 'High efficiency fast-charging USB-C wall charger compatible with iPhone, iPad, and AirPods.',
  ),
  const BarcodeProduct(
    barcode: '619659182396',
    name: 'SanDisk Ultra 64GB USB 3.0 Flash Drive',
    category: FoodCategory.electronicsAndHardware,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 480.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 1825,
    brand: 'SanDisk',
    imageUrl: 'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?auto=format&fit=crop&w=400&q=80',
    description: 'High-speed transfer speeds up to 130MB/s with USB 3.0 technology.',
  ),
  const BarcodeProduct(
    barcode: '097855149367',
    name: 'Logitech M185 Wireless Optical Mouse',
    category: FoodCategory.electronicsAndHardware,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 795.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 1825,
    brand: 'Logitech',
    imageUrl: 'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?auto=format&fit=crop&w=400&q=80',
    description: 'Reliable 2.4GHz wireless mouse with nano USB receiver and 12-month battery life.',
  ),
  const BarcodeProduct(
    barcode: '041333415014',
    name: 'Energizer Max AA Alkaline Batteries (4-Pack)',
    category: FoodCategory.electronicsAndHardware,
    defaultQuantity: 4.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 195.0,
    minimumStock: 2.0,
    defaultShelfLifeDays: 3650,
    brand: 'Energizer',
    imageUrl: 'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?auto=format&fit=crop&w=400&q=80',
    description: 'Long-lasting alkaline power with PowerSeal technology holding power up to 10 years.',
  ),

  // 🧴 Personal Care, Grooming & Beauty
  const BarcodeProduct(
    barcode: '8901030368140',
    name: 'Vaseline Deep Restore Body Lotion (400ml)',
    category: FoodCategory.personalCare,
    defaultQuantity: 400.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 335.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 730,
    brand: 'Vaseline',
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    description: 'Enriched with pure oat extract and micro-droplets of Vaseline jelly for deep skin moisture.',
  ),
  const BarcodeProduct(
    barcode: '3014260285654',
    name: "Gillette Mach3 Turbo Men's Razor",
    category: FoodCategory.personalCare,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 285.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 1095,
    brand: 'Gillette',
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    description: '3 stronger-than-steel blades designed for 15 comfortable shaves.',
  ),
  const BarcodeProduct(
    barcode: '8901030584727',
    name: 'Axe Dark Temptation Deodorant Body Spray (150ml)',
    category: FoodCategory.personalCare,
    defaultQuantity: 150.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 215.0,
    minimumStock: 50.0,
    defaultShelfLifeDays: 730,
    brand: 'Axe',
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    description: '48-hour high-definition chocolate fragrance with dual-action zinc odor-busting technology.',
  ),
  const BarcodeProduct(
    barcode: '8901030753113',
    name: "Pond's Bright Beauty Spot-less Glow Face Wash (100g)",
    category: FoodCategory.personalCare,
    defaultQuantity: 100.0,
    unit: FoodUnit.grams,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 149.0,
    minimumStock: 30.0,
    defaultShelfLifeDays: 730,
    brand: "Pond's",
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    description: 'Infused with Advanced Vitamin B3+ formula to remove dead skin cells and dark spots.',
  ),
  const BarcodeProduct(
    barcode: '8901030864321',
    name: 'Head & Shoulders Cool Menthol Anti-Dandruff Shampoo (340ml)',
    category: FoodCategory.personalCare,
    defaultQuantity: 340.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 320.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 730,
    brand: 'Head & Shoulders',
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    description: 'Menthol cooling anti-dandruff shampoo that leaves hair up to 100% dandruff-free.',
  ),

  // 🧹 Household, Cleaning & Maintenance
  const BarcodeProduct(
    barcode: '8901396321027',
    name: 'Colin Glass & Surface Cleaner Spray (500ml)',
    category: FoodCategory.householdCleaning,
    defaultQuantity: 500.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 105.0,
    minimumStock: 100.0,
    defaultShelfLifeDays: 730,
    brand: 'Colin',
    imageUrl: 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    description: 'Shine boosters provide 2x streak-free shine across glass, mirror, and smooth appliance surfaces.',
  ),
  const BarcodeProduct(
    barcode: '8901030700124',
    name: 'Comfort After Wash Fabric Conditioner (860ml)',
    category: FoodCategory.householdCleaning,
    defaultQuantity: 860.0,
    unit: FoodUnit.ml,
    storageLocation: StorageLocation.pantry,
    defaultPrice: 225.0,
    minimumStock: 200.0,
    defaultShelfLifeDays: 730,
    brand: 'Comfort',
    imageUrl: 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    description: 'Provides long-lasting fragrance and protects clothes from fiber tangles and static.',
  ),
  const BarcodeProduct(
    barcode: '8901030890123',
    name: 'Scotch-Brite Heavy Duty Scrub Sponge (Pack of 3)',
    category: FoodCategory.householdCleaning,
    defaultQuantity: 3.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 85.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 1095,
    brand: 'Scotch-Brite',
    imageUrl: 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    description: 'Combines scrub pad for tough stains with soft cellulose sponge for delicate dishware.',
  ),

  // 📝 Stationery & Office Supplies
  const BarcodeProduct(
    barcode: '8901057510011',
    name: 'Classmate Pulse Spiral Notebook A4 (300 Pages)',
    category: FoodCategory.stationeryAndOffice,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 160.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 1825,
    brand: 'Classmate',
    imageUrl: 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=400&q=80',
    description: 'Single-subject spiral bound notebook with chlorine-free eco-friendly bright pages.',
  ),
  const BarcodeProduct(
    barcode: '8901314010520',
    name: 'Camlin Kokuyo Exam Gel Pen (Pack of 5)',
    category: FoodCategory.stationeryAndOffice,
    defaultQuantity: 5.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 50.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 730,
    brand: 'Camlin',
    imageUrl: 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=400&q=80',
    description: 'Smooth waterproof gel ink with ergonomic grip suited for long examination writing.',
  ),
  const BarcodeProduct(
    barcode: '051141380123',
    name: '3M Scotch Magic Tape Dispenser (19mm x 25m)',
    category: FoodCategory.stationeryAndOffice,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 120.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 1825,
    brand: '3M',
    imageUrl: 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=400&q=80',
    description: 'Original matte-finish invisible tape. Write on it with pen, pencil, or marker.',
  ),
  const BarcodeProduct(
    barcode: '051141920152',
    name: 'Post-it Super Sticky Notes Canary Yellow (3x3 in)',
    category: FoodCategory.stationeryAndOffice,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.kitchenCabinet,
    defaultPrice: 95.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 1825,
    brand: 'Post-it',
    imageUrl: 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=400&q=80',
    description: '2x the sticking power of basic notes. Sticks and re-sticks to vertical and hard-to-stick surfaces.',
  ),

  // 🥫 Universal Soft Drinks & Dairy
  const BarcodeProduct(
    barcode: '049000000443',
    name: 'Coca-Cola Classic (12 Fl Oz Can)',
    category: FoodCategory.beverages,
    defaultQuantity: 1.0,
    unit: FoodUnit.pieces,
    storageLocation: StorageLocation.fridge,
    defaultPrice: 40.0,
    minimumStock: 2.0,
    defaultShelfLifeDays: 180,
    brand: 'Coca-Cola',
    imageUrl: 'https://images.unsplash.com/photo-1554866585-cd94860890b7?auto=format&fit=crop&w=400&q=80',
    description: 'Original refreshing crisp cola taste since 1886. Best served chilled.',
  ),
  const BarcodeProduct(
    barcode: '8901764012211',
    name: 'Amul Taaza Homogenised Toned Milk (1L)',
    category: FoodCategory.dairy,
    defaultQuantity: 1.0,
    unit: FoodUnit.litre,
    storageLocation: StorageLocation.fridge,
    defaultPrice: 72.0,
    minimumStock: 1.0,
    defaultShelfLifeDays: 90,
    brand: 'Amul',
    imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80',
    description: 'UHT treated long shelf life toned milk with 3.0% fat and 8.5% SNF. No boiling needed.',
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
        lower.contains('charger') ||
        lower.contains('usb') ||
        lower.contains('adapter') ||
        lower.contains('mouse') ||
        lower.contains('keyboard') ||
        lower.contains('sandisk') ||
        lower.contains('drive') ||
        lower.contains('headphone') ||
        lower.contains('audio') ||
        lower.contains('laptop') ||
        lower.contains('device')) {
      return FoodCategory.electronicsAndHardware;
    } else if (lower.contains('stationery') ||
        lower.contains('office') ||
        lower.contains('book') ||
        lower.contains('isbn') ||
        lower.contains('novel') ||
        lower.contains('hardcover') ||
        lower.contains('paperback') ||
        lower.contains('author') ||
        lower.contains('publisher') ||
        lower.contains('publication') ||
        lower.contains('glue') ||
        lower.contains('fevicol') ||
        lower.contains('adhesive') ||
        lower.contains('pen') ||
        lower.contains('pencil') ||
        lower.contains('tape') ||
        lower.contains('paper') ||
        lower.contains('notebook') ||
        lower.contains('post-it')) {
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

  /// Suggests logical storage location based on product category
  static StorageLocation inferStorageLocation(FoodCategory category) {
    switch (category) {
      case FoodCategory.dairy:
        return StorageLocation.fridge;
      case FoodCategory.medicines:
      case FoodCategory.personalCare:
      case FoodCategory.stationeryAndOffice:
      case FoodCategory.electronicsAndHardware:
        return StorageLocation.kitchenCabinet;
      case FoodCategory.beverages:
      case FoodCategory.householdCleaning:
      case FoodCategory.petSupplies:
      case FoodCategory.babyCare:
      case FoodCategory.grainsAndPulses:
      case FoodCategory.flourAndBaking:
      case FoodCategory.spices:
      case FoodCategory.oils:
      case FoodCategory.snacksAndPackaged:
      case FoodCategory.other:
        return StorageLocation.pantry;
    }
  }

  /// Validates that a string returned by an API is a meaningful product name (not test/dummy text)
  static bool _isValidProductName(String? name) {
    if (name == null) return false;
    final trimmed = name.trim();
    if (trimmed.length < 3) return false;
    final lower = trimmed.toLowerCase();
    if (lower == 'test' ||
        lower == 'unknown' ||
        lower == 'item' ||
        lower == 'sample' ||
        lower == 'product' ||
        lower == 'demo' ||
        lower == 'none' ||
        lower == 'null') {
      return false;
    }
    // Discard strings that are purely digits
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return false;
    return true;
  }

  /// Looks up a product by its barcode from offline presets or multi-database online queries
  /// (Open Library for Books/ISBN, UPCitemdb for Universal retail items, Open Food/Products/Beauty Facts)
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
             (p.barcode.length == 12 && cleanBarcode == '0${p.barcode}') ||
             (cleanBarcode.length == 13 && cleanBarcode.startsWith('0') && p.barcode == cleanBarcode.substring(1)),
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

    // 2. Multi-Source Online Lookup
    if (!kIsWeb) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);

      // Query A: Book / ISBN Lookup via Open Library API
      Future<BarcodeProduct?> queryOpenLibrary() async {
        final isIsbn = cleanBarcode.startsWith('978') ||
            cleanBarcode.startsWith('979') ||
            (cleanBarcode.length == 10 && RegExp(r'^[0-9Xx]+$').hasMatch(cleanBarcode));
        if (!isIsbn) return null;

        try {
          final url = 'https://openlibrary.org/api/books?bibkeys=ISBN:$cleanBarcode&format=json&jscmd=data';
          final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 4));
          request.headers.set('User-Agent', 'HomePantryApp/1.0.0 (support@homepantry.com)');
          final response = await request.close().timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final responseBody = await response.transform(utf8.decoder).join();
            final data = jsonDecode(responseBody) as Map<String, dynamic>;
            final key = 'ISBN:$cleanBarcode';
            if (data.containsKey(key)) {
              final book = data[key] as Map<String, dynamic>;
              final title = (book['title'] as String?)?.trim();
              if (title != null && title.isNotEmpty) {
                final subtitle = (book['subtitle'] as String?)?.trim();
                final authors = (book['authors'] as List<dynamic>?)
                        ?.map((a) => (a as Map<String, dynamic>)['name'] as String?)
                        .where((n) => n != null && n.isNotEmpty)
                        .cast<String>()
                        .toList() ??
                    [];
                final publishers = (book['publishers'] as List<dynamic>?)
                        ?.map((p) => (p as Map<String, dynamic>)['name'] as String?)
                        .where((p) => p != null && p.isNotEmpty)
                        .cast<String>()
                        .toList() ??
                    [];

                final fullTitle = (subtitle != null && subtitle.isNotEmpty)
                    ? '$title: $subtitle'
                    : title;

                final brand = authors.isNotEmpty
                    ? authors.join(', ')
                    : (publishers.isNotEmpty ? publishers.first : null);

                final descParts = <String>[];
                if (authors.isNotEmpty) descParts.add('Author: ${authors.join(', ')}');
                if (publishers.isNotEmpty) descParts.add('Publisher: ${publishers.join(', ')}');
                if (book['number_of_pages'] != null) descParts.add('${book['number_of_pages']} pages');
                if (book['publish_date'] != null) descParts.add('Published: ${book['publish_date']}');

                final coverMap = book['cover'] as Map<String, dynamic>?;
                final coverUrl = coverMap?['large'] as String? ??
                    coverMap?['medium'] as String? ??
                    coverMap?['small'] as String?;

                return BarcodeProduct(
                  barcode: cleanBarcode,
                  name: fullTitle,
                  category: FoodCategory.stationeryAndOffice,
                  defaultQuantity: 1.0,
                  unit: FoodUnit.pieces,
                  storageLocation: StorageLocation.kitchenCabinet,
                  defaultShelfLifeDays: 1825,
                  brand: brand,
                  imageUrl: coverUrl ?? FoodImageHelper.getEffectiveImageUrl(fullTitle, FoodCategory.stationeryAndOffice),
                  description: descParts.join(' • '),
                );
              }
            }
          }
        } catch (_) {}
        return null;
      }

      // Query B: UPCitemdb (universal commercial retail products catalog)
      Future<BarcodeProduct?> queryUpcItemDb() async {
        final upcCandidates = <String>[cleanBarcode];
        if (cleanBarcode.length == 13 && cleanBarcode.startsWith('0')) {
          upcCandidates.add(cleanBarcode.substring(1));
        } else if (cleanBarcode.length == 12) {
          upcCandidates.add('0$cleanBarcode');
        }

        for (final upc in upcCandidates) {
          try {
            final upcUrl = 'https://api.upcitemdb.com/prod/trial/lookup?upc=$upc';
            final request = await client.getUrl(Uri.parse(upcUrl)).timeout(const Duration(seconds: 4));
            request.headers.set('User-Agent', 'HomePantryApp/1.0.0 (support@homepantry.com)');
            final response = await request.close().timeout(const Duration(seconds: 4));

            if (response.statusCode == 200) {
              final responseBody = await response.transform(utf8.decoder).join();
              final data = jsonDecode(responseBody) as Map<String, dynamic>;
              final items = data['items'] as List<dynamic>?;
              if (items != null && items.isNotEmpty) {
                final item = items.first as Map<String, dynamic>;
                final title = (item['title'] as String?)?.trim();
                final brand = (item['brand'] as String?)?.trim();
                final description = (item['description'] as String?)?.trim();
                final images = (item['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                final size = (item['size'] as String?)?.trim() ??
                    (item['dimension'] as String?)?.trim() ??
                    (item['weight'] as String?)?.trim();

                if (_isValidProductName(title)) {
                  final category = inferCategory('$title ${item['category'] ?? ''} ${brand ?? ''}');
                  final shelfLife = ExpiryDateExtractor.categoryShelfLifeDays[category] ?? 365;
                  final effectiveImage = images.isNotEmpty
                      ? images.first
                      : FoodImageHelper.getEffectiveImageUrl(title!, category);

                  return BarcodeProduct(
                    barcode: cleanBarcode,
                    name: title!,
                    category: category,
                    defaultQuantity: 1.0,
                    unit: FoodUnit.pieces,
                    storageLocation: inferStorageLocation(category),
                    defaultShelfLifeDays: shelfLife,
                    brand: brand,
                    imageUrl: effectiveImage,
                    description: description,
                    packageSize: size,
                  );
                }
              }
            }
          } catch (_) {}
        }
        return null;
      }

      // Query C: Open Food Facts / Beauty / Products Facts
      final openFactsUrls = [
        'https://world.openfoodfacts.org/api/v0/product/$cleanBarcode.json',
        'https://world.openproductsfacts.org/api/v0/product/$cleanBarcode.json',
        'https://world.openbeautyfacts.org/api/v0/product/$cleanBarcode.json',
      ];

      final openFactsFutures = openFactsUrls.map((url) async {
        try {
          final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 4));
          request.headers.set('User-Agent', 'HomePantryApp/1.0.0 (support@homepantry.com)');
          final response = await request.close().timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final responseBody = await response.transform(utf8.decoder).join();
            final data = jsonDecode(responseBody) as Map<String, dynamic>;
            if (data['status'] == 1 && data['product'] != null) {
              final prod = data['product'] as Map<String, dynamic>;
              final rawName = (prod['product_name'] as String?)?.trim() ??
                  (prod['generic_name'] as String?)?.trim();

              if (_isValidProductName(rawName)) {
                final brand = (prod['brands'] as String?)?.trim();
                final categoriesTags = (prod['categories_tags'] as List<dynamic>?)
                        ?.map((e) => e.toString().toLowerCase())
                        .toList() ??
                    [];

                final directImage = prod['image_front_url'] as String? ??
                    prod['image_front_small_url'] as String? ??
                    prod['image_url'] as String?;

                final combinedText = '$rawName ${categoriesTags.join(' ')} ${brand ?? ''}';
                final category = inferCategory(combinedText);
                final displayName = brand != null &&
                        brand.isNotEmpty &&
                        !rawName!.toLowerCase().contains(brand.toLowerCase())
                    ? '$brand $rawName'
                    : rawName!;

                final shelfLife = ExpiryDateExtractor.categoryShelfLifeDays[category] ?? 365;
                final effectiveImage = directImage ?? FoodImageHelper.getEffectiveImageUrl(displayName, category);

                final desc = (prod['generic_name'] as String?)?.trim() ??
                    (prod['ingredients_text'] as String?)?.trim();
                final packageSize = (prod['quantity'] as String?)?.trim();

                return BarcodeProduct(
                  barcode: cleanBarcode,
                  name: displayName,
                  category: category,
                  defaultQuantity: 1.0,
                  unit: FoodUnit.pieces,
                  storageLocation: inferStorageLocation(category),
                  defaultShelfLifeDays: shelfLife,
                  brand: brand,
                  imageUrl: effectiveImage,
                  description: desc,
                  packageSize: packageSize,
                );
              }
            }
          }
        } catch (_) {}
        return null;
      });

      // If it looks like an ISBN book, query Open Library first
      final bookResult = await queryOpenLibrary();
      if (bookResult != null) return bookResult;

      // Execute UPCitemdb and Open Facts concurrently
      final allFutures = [queryUpcItemDb(), ...openFactsFutures];
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
    String originName = '';

    if (barcode.startsWith('978') || barcode.startsWith('979')) {
      category = FoodCategory.stationeryAndOffice;
      originName = 'Book (ISBN)';
    } else if (barcode.startsWith('890')) {
      originName = 'India';
    } else if (barcode.startsWith('50')) {
      originName = 'United Kingdom';
    } else if (barcode.startsWith('0') || barcode.startsWith('1')) {
      originName = 'US / Canada';
    } else if (barcode.startsWith('40') || barcode.startsWith('41') || barcode.startsWith('42') || barcode.startsWith('43') || barcode.startsWith('44')) {
      originName = 'Germany';
    } else if (barcode.startsWith('45') || barcode.startsWith('49')) {
      originName = 'Japan';
    } else if (barcode.startsWith('690') || barcode.startsWith('691') || barcode.startsWith('692') || barcode.startsWith('693') || barcode.startsWith('694') || barcode.startsWith('695')) {
      originName = 'China';
    } else if (barcode.startsWith('30') || barcode.startsWith('31') || barcode.startsWith('32') || barcode.startsWith('33') || barcode.startsWith('34') || barcode.startsWith('35') || barcode.startsWith('36') || barcode.startsWith('37')) {
      originName = 'France';
    } else if (barcode.startsWith('80') || barcode.startsWith('81') || barcode.startsWith('82') || barcode.startsWith('83')) {
      originName = 'Italy';
    } else if (barcode.startsWith('84')) {
      originName = 'Spain';
    } else if (barcode.startsWith('880')) {
      originName = 'South Korea';
    } else if (barcode.startsWith('885')) {
      originName = 'Thailand';
    } else if (barcode.startsWith('888')) {
      originName = 'Singapore';
    } else if (barcode.startsWith('93')) {
      originName = 'Australia';
    }

    final name = originName.isNotEmpty
        ? (originName.startsWith('Book') ? '$originName $barcode' : 'Product of $originName (SKU $barcode)')
        : 'Scanned Product ($barcode)';
    final shelfLife = ExpiryDateExtractor.categoryShelfLifeDays[category] ?? 365;
    final storageLocation = inferStorageLocation(category);
    final description = originName.isNotEmpty
        ? 'Unlisted GS1 product ($barcode) registered in $originName. You can customize the name, category, and storage location.'
        : 'Unlisted barcode product ($barcode). You can customize the name, category, and storage location.';

    return BarcodeProduct(
      barcode: barcode,
      name: name,
      category: category,
      defaultQuantity: 1.0,
      unit: FoodUnit.pieces,
      storageLocation: storageLocation,
      defaultShelfLifeDays: shelfLife,
      description: description,
      imageUrl: FoodImageHelper.getEffectiveImageUrl(name, category),
    );
  }
}

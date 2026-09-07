import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app/theme/color_palette.dart';
import '../../features/food_inventory/domain/entities/food_category.dart';
import '../../features/food_inventory/domain/entities/food_item.dart';

/// Helper utility that provides rich product photography across groceries, medicines, personal care, household, etc.
class FoodImageHelper {
  FoodImageHelper._();

  static const Map<String, String> _curatedFoodImages = {
    // 💊 Medicines & Pharmaceuticals
    'dolo 650': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'paracetamol': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'crocin': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'dettol': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'antiseptic': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'cough syrup': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'vitamins': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'iodex': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'volini': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',

    // 🧴 Personal Care & Cosmetics
    'dove shampoo': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    'shampoo': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    'nivea body lotion': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    'lotion': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    'colgate total': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    'toothpaste': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    'sunscreen': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    'face wash': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    'soap': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    'perfume': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',

    // 🧹 Cleaning & Household
    'surf excel': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    'detergent': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    'lizol': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    'floor cleaner': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    'vim dishwash': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    'dishwash': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    'harpic': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    'disinfectant': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',

    // 🐶 Pet Supplies
    'pedigree': 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?auto=format&fit=crop&w=400&q=80',
    'dog food': 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?auto=format&fit=crop&w=400&q=80',
    'whiskas': 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?auto=format&fit=crop&w=400&q=80',
    'cat food': 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?auto=format&fit=crop&w=400&q=80',

    // 👶 Baby Care
    'johnson baby': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80',
    'baby lotion': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80',
    'diapers': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80',
    'pampers': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80',
    'cerelac': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80',

    // 🔋 Electronics & Hardware
    'duracell': 'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?auto=format&fit=crop&w=400&q=80',
    'battery': 'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?auto=format&fit=crop&w=400&q=80',
    'batteries': 'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?auto=format&fit=crop&w=400&q=80',
    'fevicol': 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=400&q=80',
    'adhesive': 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=400&q=80',
    'glue': 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=400&q=80',

    // 🌾 Grains & Pulses
    'basmati rice': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
    'rice': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
    'red lentils': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',
    'masoor dal': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',
    'lentils': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',
    'dal': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',
    'chickpeas': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',
    'garbanzo': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',
    'chana': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',
    'rolled oats': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
    'oats': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
    'quinoa': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
    'kidney beans': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',
    'rajma': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=400&q=80',

    // 🍞 Flour & Baking
    'wheat flour': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
    'atta': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
    'flour': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
    'maida': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
    'sugar': 'https://images.unsplash.com/photo-1581441363689-1f3c3c414635?auto=format&fit=crop&w=400&q=80',
    'baking powder': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
    'sourdough bread': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
    'bread': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',

    // 🥛 Dairy
    'whole milk': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80',
    'milk': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80',
    'greek yogurt': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=400&q=80',
    'yogurt': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=400&q=80',
    'curd': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=400&q=80',
    'cheese': 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=400&q=80',
    'butter': 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&w=400&q=80',
    'fresh eggs': 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=400&q=80',
    'eggs': 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=400&q=80',
    'paneer': 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=400&q=80',

    // 🧂 Spices
    'salt': 'https://images.unsplash.com/photo-1518110925495-5fe2fda0442c?auto=format&fit=crop&w=400&q=80',
    'turmeric': 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=400&q=80',
    'black pepper': 'https://images.unsplash.com/photo-1509358271058-acd22cc93898?auto=format&fit=crop&w=400&q=80',
    'spices': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=400&q=80',

    // 🫒 Oils & Ghee
    'olive oil': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
    'sunflower oil': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
    'ghee': 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&w=400&q=80',

    // 🍪 Snacks & Packaged Foods
    'maggi': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=400&q=80',
    'ramen': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=400&q=80',
    'noodles': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=400&q=80',
    'pasta': 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=400&q=80',
    'chips': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=400&q=80',
    'kurkure': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=400&q=80',
    'lays': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=400&q=80',
    'biscuits': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=400&q=80',
    'cookies': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=400&q=80',

    // ☕ Beverages
    'green tea': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=400&q=80',
    'tea': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=400&q=80',
    'coffee': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?auto=format&fit=crop&w=400&q=80',
  };

  /// Category default high-definition fallback imagery
  static const Map<FoodCategory, String> _categoryFallbackImages = {
    FoodCategory.grainsAndPulses:
        'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
    FoodCategory.flourAndBaking:
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
    FoodCategory.dairy:
        'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80',
    FoodCategory.spices:
        'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=400&q=80',
    FoodCategory.oils:
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
    FoodCategory.snacksAndPackaged:
        'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=400&q=80',
    FoodCategory.beverages:
        'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=400&q=80',
    FoodCategory.medicines:
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    FoodCategory.personalCare:
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
    FoodCategory.householdCleaning:
        'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80',
    FoodCategory.petSupplies:
        'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?auto=format&fit=crop&w=400&q=80',
    FoodCategory.babyCare:
        'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80',
    FoodCategory.stationeryAndOffice:
        'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=400&q=80',
    FoodCategory.electronicsAndHardware:
        'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?auto=format&fit=crop&w=400&q=80',
    FoodCategory.other:
        'https://images.unsplash.com/photo-1584473457406-624048518851?auto=format&fit=crop&w=400&q=80',
  };

  /// Banner image URL for the hero card (clean pantry jars)
  static const String pantryHeroImageUrl =
      'https://images.unsplash.com/photo-1584473457406-624048518851?auto=format&fit=crop&w=1200&q=85';

  /// Returns the effective image URL or local file path for an item, matching the resolution used across the app
  static String getEffectiveItemImagePath(FoodItem item) {
    final imagePath = item.imagePath?.trim();
    if (imagePath != null &&
        (imagePath.startsWith('http://') || imagePath.startsWith('https://'))) {
      return imagePath;
    }
    if (imagePath != null &&
        imagePath.isNotEmpty &&
        !kIsWeb &&
        File(imagePath).existsSync()) {
      return imagePath;
    }
    return getEffectiveImageUrl(item.name, item.category);
  }

  /// Returns a curated photo URL for items by name or category fallback
  static String getEffectiveImageUrl(String productName, FoodCategory category) {
    final cleanName = productName.trim().toLowerCase();
    for (final entry in _curatedFoodImages.entries) {
      if (cleanName.contains(entry.key)) {
        return entry.value;
      }
    }
    return _categoryFallbackImages[category] ??
        'https://images.unsplash.com/photo-1584473457406-624048518851?auto=format&fit=crop&w=400&q=80';
  }

  /// Builds a responsive product thumbnail or full card image widget
  static Widget buildFoodImage({
    required FoodItem item,
    required double width,
    required double height,
    double borderRadius = 16,
    BoxFit fit = BoxFit.cover,
    bool isDark = false,
  }) {
    final imagePath = item.imagePath?.trim();

    // 1. Direct Network Image URL stored in imagePath
    if (imagePath != null && (imagePath.startsWith('http://') || imagePath.startsWith('https://'))) {
      return _buildNetworkImage(
        url: imagePath,
        category: item.category,
        fallbackName: item.name,
        width: width,
        height: height,
        borderRadius: borderRadius,
        fit: fit,
        isDark: isDark,
      );
    }

    // 2. Local user-captured image file
    if (imagePath != null && imagePath.isNotEmpty && !kIsWeb) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildOnlinePhoto(
              item: item,
              width: width,
              height: height,
              borderRadius: borderRadius,
              fit: fit,
              isDark: isDark,
            ),
          ),
        );
      }
    }

    // 3. Curated online photography matching the product
    return _buildOnlinePhoto(
      item: item,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: fit,
      isDark: isDark,
    );
  }

  static Widget _buildNetworkImage({
    required String url,
    required FoodCategory category,
    required String fallbackName,
    required double width,
    required double height,
    required double borderRadius,
    required BoxFit fit,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: (width * 2.5).clamp(80, 500).round(),
        cacheHeight: (height * 2.5).clamp(80, 500).round(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: ColorPalette.freshEmerald,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          final fallbackUrl = getEffectiveImageUrl(fallbackName, category);
          if (fallbackUrl != url) {
            return Image.network(
              fallbackUrl,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => buildCategoryPlaceholder(
                category: category,
                width: width,
                height: height,
                borderRadius: borderRadius,
                isDark: isDark,
              ),
            );
          }
          return buildCategoryPlaceholder(
            category: category,
            width: width,
            height: height,
            borderRadius: borderRadius,
            isDark: isDark,
          );
        },
      ),
    );
  }

  static Widget _buildOnlinePhoto({
    required FoodItem item,
    required double width,
    required double height,
    required double borderRadius,
    required BoxFit fit,
    required bool isDark,
  }) {
    final photoUrl = getEffectiveImageUrl(item.name, item.category);
    return _buildNetworkImage(
      url: photoUrl,
      category: item.category,
      fallbackName: item.name,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: fit,
      isDark: isDark,
    );
  }

  /// Builds a fallback placeholder with category colors and icons
  static Widget buildCategoryPlaceholder({
    required FoodCategory category,
    required double width,
    required double height,
    double borderRadius = 16,
    bool isDark = false,
    double iconSize = 24,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: category.color.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Icon(
          category.icon,
          size: iconSize,
          color: category.color,
        ),
      ),
    );
  }
}

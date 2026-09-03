import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/storage_location.dart';

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
  ),
];

/// Interactive Barcode Scanner & Offline Lookup Sheet
class BarcodeScannerSheet extends StatefulWidget {
  final ValueChanged<BarcodeProduct> onProductScanned;

  const BarcodeScannerSheet({
    super.key,
    required this.onProductScanned,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<BarcodeProduct> onProductScanned,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BarcodeScannerSheet(onProductScanned: onProductScanned),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final _searchController = TextEditingController();
  List<BarcodeProduct> _filteredProducts = offlineBarcodeCatalog;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredProducts = offlineBarcodeCatalog;
      } else {
        final q = query.trim().toLowerCase();
        _filteredProducts = offlineBarcodeCatalog.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.barcode.contains(q) ||
              p.category.label.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0284C7), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Grocery Barcode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Offline grocery SKU recognition',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simulated Optical Scanner Viewfinder Frame
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ColorPalette.freshEmerald, width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.line_weight_rounded, color: Colors.white70, size: 40),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorPalette.freshEmerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Align barcode within frame or tap a match below',
                        style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                // Glowing laser scan line
                Positioned(
                  top: 60,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: ColorPalette.freshEmerald,
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.freshEmerald.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search / Enter Barcode
          TextField(
            controller: _searchController,
            onChanged: _filter,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search SKU or enter barcode digits...',
              filled: true,
              fillColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Product List
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      'No matching barcode product found in offline catalog.\nYou can enter details manually in the form.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? ColorPalette.darkTextTertiary : ColorPalette.lightTextTertiary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = _filteredProducts[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: p.category.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(p.category.icon, color: p.category.color, size: 20),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          '${p.category.label} • ${p.defaultQuantity.toStringAsFixed(0)} ${p.unit.label} • ₹${p.defaultPrice?.toStringAsFixed(0) ?? '0'}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                          ),
                        ),
                        trailing: const Icon(Icons.check_circle_outline_rounded, color: ColorPalette.freshEmerald),
                        onTap: () {
                          widget.onProductScanned(p);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

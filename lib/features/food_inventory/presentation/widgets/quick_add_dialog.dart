import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/color_palette.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/storage_location.dart';
import '../providers/food_list_controller.dart';
import '../screens/barcode_scanner_screen.dart';

/// Quick Add Dialog for adding groceries in seconds with smart presets
class QuickAddDialog extends ConsumerStatefulWidget {
  const QuickAddDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddDialog(),
    );
  }

  @override
  ConsumerState<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends ConsumerState<QuickAddDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  FoodCategory _category = FoodCategory.dairy;
  FoodUnit _unit = FoodUnit.pieces;
  StorageLocation _storageLocation = StorageLocation.fridge;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 3));
  String? _barcode;

  final List<Map<String, dynamic>> _quickPresets = [
    {
      'name': 'Whole Milk',
      'category': FoodCategory.dairy,
      'unit': FoodUnit.ml,
      'qty': '1000',
      'days': 4,
      'location': StorageLocation.fridge,
      'price': '64',
    },
    {
      'name': 'Sourdough Bread',
      'category': FoodCategory.flourAndBaking,
      'unit': FoodUnit.pieces,
      'qty': '1',
      'days': 3,
      'location': StorageLocation.kitchenCabinet,
      'price': '90',
    },
    {
      'name': 'Greek Yogurt',
      'category': FoodCategory.dairy,
      'unit': FoodUnit.grams,
      'qty': '400',
      'days': 5,
      'location': StorageLocation.fridge,
      'price': '120',
    },
    {
      'name': 'Basmati Rice',
      'category': FoodCategory.grainsAndPulses,
      'unit': FoodUnit.kg,
      'qty': '5',
      'days': 180,
      'location': StorageLocation.pantry,
      'price': '420',
    },
    {
      'name': 'Sunflower Oil',
      'category': FoodCategory.oils,
      'unit': FoodUnit.litre,
      'qty': '1',
      'days': 180,
      'location': StorageLocation.pantry,
      'price': '190',
    },
    {
      'name': 'Green Tea Bags',
      'category': FoodCategory.beverages,
      'unit': FoodUnit.pieces,
      'qty': '25',
      'days': 120,
      'location': StorageLocation.kitchenCabinet,
      'price': '150',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'] as String;
      _category = preset['category'] as FoodCategory;
      _unit = preset['unit'] as FoodUnit;
      _quantityController.text = preset['qty'] as String;
      _storageLocation = preset['location'] as StorageLocation;
      _priceController.text = preset['price'] as String;
      final days = preset['days'] as int;
      _expiryDate = DateTime.now().add(Duration(days: days));
    });
  }

  void _scanBarcode() async {
    final product = await BarcodeScannerScreen.open(context);
    if (product != null) {
      setState(() {
        if (product.name.isNotEmpty) {
          _nameController.text = product.name;
        }
        _category = product.category;
        _unit = product.unit;
        _storageLocation = product.storageLocation;
        _quantityController.text = product.defaultQuantity.toStringAsFixed(
          product.defaultQuantity.truncateToDouble() == product.defaultQuantity ? 0 : 1,
        );
        if (product.defaultPrice != null) {
          _priceController.text = product.defaultPrice!.toStringAsFixed(0);
        }
        _barcode = product.barcode;
        _expiryDate = DateTime.now().add(Duration(days: product.defaultShelfLifeDays));
      });
    }
  }

  void _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a grocery name')),
      );
      return;
    }

    final qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;
    final price = double.tryParse(_priceController.text.trim());

    await ref.read(foodListControllerProvider.notifier).quickAddFood(
          name: name,
          quantity: qty,
          expiryDate: _expiryDate,
          category: _category,
          unit: _unit,
          location: _storageLocation,
          price: price,
          barcode: _barcode,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $name to ${_storageLocation.label}!'),
          backgroundColor: ColorPalette.freshEmeraldDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    color: ColorPalette.freshEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: ColorPalette.freshEmerald, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quick Add Grocery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: ColorPalette.freshEmerald),
                  label: const Text(
                    'Scan',
                    style: TextStyle(fontWeight: FontWeight.w800, color: ColorPalette.freshEmerald),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Scan Barcode Card Banner
            InkWell(
              onTap: _scanBarcode,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F3B2C), const Color(0xFF064E3B)]
                        : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ColorPalette.freshEmerald.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ColorPalette.freshEmerald.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: ColorPalette.freshEmerald,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _barcode != null && _barcode!.isNotEmpty
                                ? 'Scanned: $_barcode (Tap to Rescan)'
                                : 'Scan Grocery Barcode',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? ColorPalette.freshEmerald : ColorPalette.freshEmeraldDark,
                            ),
                          ),
                          Text(
                            'Point camera at packaging to auto-fill details',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: ColorPalette.freshEmerald),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick Preset Chips
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickPresets.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ActionChip(
                      avatar: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                      label: const Text('Scan SKU'),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      backgroundColor: ColorPalette.freshEmerald,
                      onPressed: _scanBarcode,
                    );
                  }
                  final preset = _quickPresets[index - 1];
                  return ActionChip(
                    label: Text(preset['name'] as String),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                    ),
                    backgroundColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
                    side: BorderSide(
                      color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                    ),
                    onPressed: () => _applyPreset(preset),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Grocery Name Input
            TextField(
              controller: _nameController,
              autofocus: true,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Grocery Item Name *',
                hintText: 'e.g. Whole Milk, Basmati Rice',
                filled: true,
                fillColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.shopping_basket_outlined, color: ColorPalette.freshEmerald),
              ),
            ),
            const SizedBox(height: 12),

            // Quantity & Unit & Price Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      filled: true,
                      fillColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<FoodUnit>(
                    initialValue: _unit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      filled: true,
                      fillColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: FoodUnit.values.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u.label, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price (₹)',
                      filled: true,
                      fillColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category & Storage Location Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<FoodCategory>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: FoodCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(c.icon, size: 16, color: c.color),
                            const SizedBox(width: 6),
                            Expanded(child: Text(c.label, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _category = v ?? _category),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<StorageLocation>(
                    initialValue: _storageLocation,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      filled: true,
                      fillColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: StorageLocation.values.map((loc) {
                      return DropdownMenuItem(
                        value: loc,
                        child: Row(
                          children: [
                            Icon(loc.icon, size: 16, color: loc.color),
                            const SizedBox(width: 6),
                            Expanded(child: Text(loc.label, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _storageLocation = v ?? _storageLocation),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Expiry Date Presets
            Text(
              'Expiry Date Presets',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildDateChip('Tomorrow', 1),
                _buildDateChip('3 Days', 3),
                _buildDateChip('7 Days', 7),
                _buildDateChip('1 Month', 30),
                _buildDateChip('6 Months', 180),
              ],
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                label: const Text(
                  'Add to Pantry',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.freshEmerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, int days) {
    final targetDate = DateTime.now().add(Duration(days: days));
    final isSelected = _expiryDate.day == targetDate.day &&
        _expiryDate.month == targetDate.month &&
        _expiryDate.year == targetDate.year;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: ColorPalette.freshEmerald,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : null,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _expiryDate = targetDate);
        }
      },
    );
  }
}

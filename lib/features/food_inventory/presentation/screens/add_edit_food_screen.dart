import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/storage_location.dart';
import '../providers/food_form_controller.dart';
import 'barcode_scanner_screen.dart';

/// Screen for adding new groceries or editing existing items
class AddEditFoodScreen extends ConsumerStatefulWidget {
  final FoodItem? initialItem;

  const AddEditFoodScreen({super.key, this.initialItem});

  @override
  ConsumerState<AddEditFoodScreen> createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends ConsumerState<AddEditFoodScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _minStockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialItem?.name ?? '');
    _notesController = TextEditingController(text: widget.initialItem?.notes ?? '');
    _quantityController = TextEditingController(
      text: widget.initialItem != null
          ? widget.initialItem!.remainingQuantity.toStringAsFixed(
              widget.initialItem!.remainingQuantity.truncateToDouble() ==
                      widget.initialItem!.remainingQuantity
                  ? 0
                  : 1)
          : '1',
    );
    _priceController = TextEditingController(
      text: widget.initialItem?.price != null
          ? widget.initialItem!.price!.toStringAsFixed(
              widget.initialItem!.price!.truncateToDouble() == widget.initialItem!.price
                  ? 0
                  : 2)
          : '',
    );
    _minStockController = TextEditingController(
      text: widget.initialItem?.minimumStock != null
          ? widget.initialItem!.minimumStock!.toStringAsFixed(
              widget.initialItem!.minimumStock!.truncateToDouble() ==
                      widget.initialItem!.minimumStock
                  ? 0
                  : 1)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _showBarcodeScanner(BuildContext context, FoodFormController notifier) async {
    final product = await BarcodeScannerScreen.open(context);
    if (product != null) {
      setState(() {
        if (product.name.isNotEmpty) {
          _nameController.text = product.name;
        }
        _quantityController.text = product.defaultQuantity.toStringAsFixed(
          product.defaultQuantity.truncateToDouble() == product.defaultQuantity ? 0 : 1,
        );
        if (product.defaultPrice != null) {
          _priceController.text = product.defaultPrice!.toStringAsFixed(0);
        }
        if (product.minimumStock != null) {
          _minStockController.text = product.minimumStock!.toStringAsFixed(0);
        }
      });

      if (product.name.isNotEmpty) {
        notifier.setName(product.name);
      }
      notifier.setCategory(product.category);
      notifier.setStorageLocation(product.storageLocation);
      notifier.setQuantity(product.defaultQuantity);
      notifier.setUnit(product.unit);
      if (product.defaultPrice != null) {
        notifier.setPrice(product.defaultPrice);
      }
      if (product.minimumStock != null) {
        notifier.setMinimumStock(product.minimumStock);
      }
      notifier.setBarcode(product.barcode);
      notifier.setExpiryDate(product.estimatedExpiryDate);
      notifier.setImagePath(product.effectiveImageUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product.name.isNotEmpty
                        ? 'Captured ${product.name} with photo & expiry date!'
                        : 'Captured barcode ${product.barcode}!',
                  ),
                ),
              ],
            ),
            backgroundColor: ColorPalette.freshEmeraldDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Attach Grocery Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? ColorPalette.darkTextPrimary
                          : ColorPalette.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorPalette.freshEmerald.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: ColorPalette.freshEmerald,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Take a Photo with Camera',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Capture package or receipt directly',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref
                        .read(foodFormControllerProvider(widget.initialItem).notifier)
                        .pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery / Photos',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Select an existing image from your device',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref
                        .read(foodFormControllerProvider(widget.initialItem).notifier)
                        .pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formState = ref.watch(foodFormControllerProvider(widget.initialItem));
    final notifier = ref.read(foodFormControllerProvider(widget.initialItem).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          formState.isEditing ? 'Edit Grocery Item' : 'Add Grocery Item',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Barcode scanner trigger
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan barcode',
            onPressed: () => _showBarcodeScanner(context, notifier),
          ),
          // Favorite toggle
          IconButton(
            icon: Icon(
              formState.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: formState.isFavorite ? ColorPalette.warningAmber : null,
            ),
            tooltip: formState.isFavorite ? 'Unfavorite' : 'Favorite',
            onPressed: notifier.toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error Banner if present
            if (formState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? ColorPalette.expiredRedDarkBg.withValues(alpha: 0.4)
                      : ColorPalette.expiredRedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorPalette.expiredRed.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: ColorPalette.expiredRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formState.errorMessage!,
                        style: const TextStyle(
                          color: ColorPalette.expiredRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Photo Attachment Section
            _buildPhotoPicker(context, formState, notifier, isDark),

            const SizedBox(height: 20),

            // Prominent Scan Barcode Button
            InkWell(
              onTap: () => _showBarcodeScanner(context, notifier),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                      color: ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.2 : 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formState.barcode != null && formState.barcode!.isNotEmpty
                          ? 'Barcode: ${formState.barcode} (Tap to Rescan)'
                          : '📷 Scan Barcode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? ColorPalette.freshEmerald : ColorPalette.freshEmeraldDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Grocery Item Name Field
            AppTextField(
              label: 'Grocery Item Name *',
              hint: 'e.g. Basmati Rice, Olive Oil, Whole Milk, Turmeric...',
              controller: _nameController,
              onChanged: notifier.setName,
              prefixIcon: const Icon(Icons.shopping_basket_rounded, size: 20),
            ),

            const SizedBox(height: 20),

            // Grocery Category Selection Chips
            Text(
              'Grocery Category *',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FoodCategory.values.map((cat) {
                final isSelected = formState.category == cat;
                return ChoiceChip(
                  avatar: Icon(
                    cat.icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : cat.color),
                  ),
                  label: Text(cat.label),
                  selected: isSelected,
                  selectedColor: cat.color,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (_) => notifier.setCategory(cat),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Storage Location Selector
            Text(
              'Storage Location *',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StorageLocation.values.map((loc) {
                final isSelected = formState.storageLocation == loc;
                return ChoiceChip(
                  avatar: Icon(
                    loc.icon,
                    size: 16,
                    color: isSelected ? Colors.white : loc.color,
                  ),
                  label: Text(loc.label),
                  selected: isSelected,
                  selectedColor: loc.color,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (_) => notifier.setStorageLocation(loc),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Purchase Date & Expiry Date Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Date',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: formState.purchaseDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            notifier.setPurchaseDate(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: ColorPalette.freshEmerald),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  DateFormatter.formatDate(formState.purchaseDate),
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Expiry Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expiry Date *',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: formState.expiryDate,
                            firstDate: formState.purchaseDate,
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) {
                            notifier.setExpiryDate(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: ColorPalette.warningAmber.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_busy_rounded, size: 18, color: ColorPalette.warningAmber),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  DateFormatter.formatDate(formState.expiryDate),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: ColorPalette.warningAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick Expiry Preset Chips
            Row(
              children: [
                _buildPresetChip('+3 Days', const Duration(days: 3), formState, notifier),
                const SizedBox(width: 6),
                _buildPresetChip('+1 Wk', const Duration(days: 7), formState, notifier),
                const SizedBox(width: 6),
                _buildPresetChip('+1 Mo', const Duration(days: 30), formState, notifier),
                const SizedBox(width: 6),
                _buildPresetChip('+6 Mo', const Duration(days: 180), formState, notifier),
                const SizedBox(width: 6),
                _buildPresetChip('+1 Yr', const Duration(days: 365), formState, notifier),
              ],
            ),

            const SizedBox(height: 24),

            // Quantity & Unit Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity *',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 18),
                              onPressed: formState.quantity > 0.5
                                  ? () {
                                      final newQ = formState.quantity - 0.5;
                                      _quantityController.text = newQ.toStringAsFixed(
                                          newQ.truncateToDouble() == newQ ? 0 : 1);
                                      notifier.setQuantity(newQ);
                                    }
                                  : null,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  final numVal = double.tryParse(val);
                                  if (numVal != null && numVal > 0) {
                                    notifier.setQuantity(numVal);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              onPressed: () {
                                final newQ = formState.quantity + 0.5;
                                _quantityController.text = newQ.toStringAsFixed(
                                    newQ.truncateToDouble() == newQ ? 0 : 1);
                                notifier.setQuantity(newQ);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<FoodUnit>(
                            isExpanded: true,
                            value: formState.unit,
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                            items: FoodUnit.values.map((unit) {
                              return DropdownMenuItem<FoodUnit>(
                                value: unit,
                                child: Text(
                                  '${unit.displayName} (${unit.abbreviation})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) notifier.setUnit(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Minimum Stock & Price in ₹ Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Min Stock Alert (Optional)',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _minStockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) {
                          notifier.setMinimumStock(double.tryParse(v.trim()));
                        },
                        decoration: InputDecoration(
                          hintText: 'e.g. 2',
                          filled: true,
                          fillColor: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                          prefixIcon: const Icon(Icons.notifications_active_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price in ₹ (Optional)',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) {
                          notifier.setPrice(double.tryParse(v.trim()));
                        },
                        decoration: InputDecoration(
                          hintText: 'e.g. 250',
                          filled: true,
                          fillColor: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                          prefixIcon: const Center(
                            widthFactor: 1,
                            child: Text('₹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Recurring Grocery Option
            Material(
              color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Recurring Grocery', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                      'Remind to repurchase on a regular schedule',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: formState.isRecurring,
                    activeThumbColor: ColorPalette.freshEmerald,
                    onChanged: (val) => notifier.setIsRecurring(val),
                  ),
                  if (formState.isRecurring) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Text('Frequency: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const Spacer(),
                          Wrap(
                            spacing: 6,
                            children: [7, 14, 30, 45].map((days) {
                              final isSelected = formState.recurringIntervalDays == days;
                              return ChoiceChip(
                                label: Text('$days d'),
                                selected: isSelected,
                                selectedColor: ColorPalette.freshEmerald,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : null,
                                ),
                                onSelected: (_) => notifier.setRecurringInterval(days),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Storage Notes
            AppTextField(
              label: 'Pantry & Storage Notes (Optional)',
              hint: 'e.g. Stored in airtight jar on top shelf, batch #2...',
              controller: _notesController,
              maxLines: 3,
              maxLength: 250,
              onChanged: notifier.setNotes,
            ),

            const SizedBox(height: 32),

            // Submit Button
            AppButton(
              label: formState.isEditing ? 'Save Changes' : 'Add to Pantry',
              icon: formState.isEditing ? Icons.check_rounded : Icons.save_rounded,
              isLoading: formState.isSubmitting,
              onPressed: () async {
                final success = await notifier.submit();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        formState.isEditing
                            ? 'Updated ${formState.name}!'
                            : 'Added ${formState.name} to grocery pantry!',
                      ),
                      backgroundColor: ColorPalette.freshEmeraldDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  context.pop();
                }
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    Duration duration,
    FoodFormState state,
    FoodFormController notifier,
  ) {
    final targetDate = DateTime.now().add(duration);
    final isSelected = state.expiryDate.year == targetDate.year &&
        state.expiryDate.month == targetDate.month &&
        state.expiryDate.day == targetDate.day;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: isSelected
            ? (isDark ? ColorPalette.warningAmberDarkBg : ColorPalette.warningAmberBg)
            : (isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected
                ? ColorPalette.warningAmber
                : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => notifier.setExpiryDate(targetDate),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? ColorPalette.warningAmber
                      : (isDark
                          ? ColorPalette.darkTextSecondary
                          : ColorPalette.lightTextSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(
    BuildContext context,
    FoodFormState formState,
    FoodFormController notifier,
    bool isDark,
  ) {
    final imagePath = formState.imagePath?.trim();
    final isUrl = imagePath != null && (imagePath.startsWith('http://') || imagePath.startsWith('https://'));
    final isLocalFile = imagePath != null && !isUrl && !kIsWeb && File(imagePath).existsSync();

    if (isUrl || isLocalFile) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ColorPalette.freshEmerald.withValues(alpha: 0.4),
            width: 1.4,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => FullScreenImageViewer.show(
                context,
                imagePath: imagePath,
                title: formState.name.isNotEmpty ? formState.name : 'Grocery Photo Preview',
              ),
              child: isUrl
                  ? Image.network(
                      imagePath,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 190,
                        width: double.infinity,
                        color: formState.category.color.withValues(alpha: 0.15),
                        child: Icon(formState.category.icon, color: formState.category.color, size: 48),
                      ),
                    )
                  : Image.file(
                      File(imagePath),
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),

            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Tap to Zoom',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      onPressed: () => _showImageSourceDialog(context),
                      tooltip: 'Change photo',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: ColorPalette.sunsetCoral, size: 16),
                      onPressed: notifier.removeImage,
                      tooltip: 'Remove photo',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? ColorPalette.freshEmerald.withValues(alpha: 0.3)
              : ColorPalette.lightBorder,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showImageSourceDialog(context),
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.12 : 0.05),
                isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: ColorPalette.freshButtonGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: ColorPalette.freshEmerald.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_a_photo_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add Product Photo (Camera or Gallery)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? ColorPalette.darkTextPrimary
                      : ColorPalette.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Help identify packaging, label, or batch',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? ColorPalette.darkTextSecondary
                      : ColorPalette.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

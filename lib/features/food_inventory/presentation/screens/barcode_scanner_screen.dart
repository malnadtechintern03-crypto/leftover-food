import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/services/barcode_lookup_service.dart';
import '../../../../core/utils/expiry_date_extractor.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/storage_location.dart';
import '../providers/food_inventory_providers.dart';
import '../providers/food_list_controller.dart';
import 'add_edit_food_screen.dart';

/// Dedicated Universal Barcode Scanner Screen with live camera preview, overlay reticle,
/// duplicate detection, automatic product details capture (name, brand, expiry date, category, unit, price)
/// and automatic product imagery across groceries, medicines, cosmetics, household supplies, and more.
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  final bool returnResult;
  final ValueChanged<BarcodeProduct>? onProductSelected;

  const BarcodeScannerScreen({
    super.key,
    this.returnResult = false,
    this.onProductSelected,
  });

  static Future<BarcodeProduct?> open(BuildContext context) async {
    return await Navigator.of(context).push<BarcodeProduct>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(returnResult: true),
      ),
    );
  }

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animController;

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    // Support ALL 1D and 2D barcode formats without restriction
    // (EAN, UPC, Code 128, Data Matrix on medicines, ITF on cartons, QR, Codabar)
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcodeDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue?.trim() ?? barcode.displayValue?.trim();
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    await _processBarcode(code);
  }

  Future<void> _processBarcode(String rawBarcode) async {
    final cleanCode = rawBarcode.trim();

    // 1. Check if item with this barcode already exists in active SQLite pantry
    FoodItem? existingItem;
    try {
      existingItem = await ref.read(getFoodItemByBarcodeUseCaseProvider).call(cleanCode);
    } catch (e) {
      debugPrint('Error checking duplicate barcode: $e');
    }

    if (!mounted) return;

    if (existingItem != null) {
      // Show duplicate alert dialog
      await _showDuplicateBarcodeDialog(existingItem, cleanCode);
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      return;
    }

    // 2. Lookup product details from offline catalog or safe online query
    final lookupProduct = await BarcodeLookupService.instance.lookupProduct(cleanCode);

    final resolvedProduct = lookupProduct ??
        BarcodeLookupService.createSmartFallbackProduct(cleanCode);

    if (!mounted) return;

    // If caller requested direct return (e.g. from AddEditFoodScreen or QuickAddDialog)
    if (widget.returnResult || widget.onProductSelected != null) {
      widget.onProductSelected?.call(resolvedProduct);
      Navigator.of(context).pop(resolvedProduct);
      return;
    }

    // Show interactive Product Detected modal preview directly over camera
    await _showProductDetectedSheet(resolvedProduct);

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showProductDetectedSheet(BarcodeProduct product) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ProductCapturedModalSheet(
          product: product,
          onAddSuccess: (name, location) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Added "$name" to $location!')),
                    ],
                  ),
                  backgroundColor: ColorPalette.freshEmeraldDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _showDuplicateBarcodeDialog(FoodItem item, String barcode) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorPalette.warningAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: ColorPalette.warningAmber, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Item In Inventory',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This product barcode ($barcode) is already in your inventory:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(item.category.icon, size: 24, color: item.category.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.remainingQuantity.toStringAsFixed(item.remainingQuantity.truncateToDouble() == item.remainingQuantity ? 0 : 1)} ${item.unit.displayName} • Expires ${item.expiryDate.day}/${item.expiryDate.month}/${item.expiryDate.year}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final product = BarcodeProduct(
                  barcode: barcode,
                  name: item.name,
                  category: item.category,
                  defaultQuantity: item.remainingQuantity,
                  unit: item.unit,
                  storageLocation: item.storageLocation,
                  defaultPrice: item.price,
                  minimumStock: item.minimumStock,
                );
                if (widget.onProductSelected != null) {
                  widget.onProductSelected!(product);
                  Navigator.of(context).pop(product);
                } else {
                  _showProductDetectedSheet(product);
                }
              },
              child: const Text('Add Another'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.freshEmerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
                context.push(RoutePaths.foodDetailPath(item.id));
              },
              child: const Text(
                'View Details',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showManualEntryDialog() {
    final textController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.keyboard_alt_rounded, color: ColorPalette.freshEmerald),
              SizedBox(width: 8),
              Text('Enter Barcode Manually', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Type or paste any product barcode (groceries, medicines, cosmetics, household & more):',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Barcode SKU',
                  hintText: 'e.g. 8901117002010 or Dolo 650',
                  prefixIcon: const Icon(Icons.qr_code_rounded, color: ColorPalette.freshEmerald),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.freshEmerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final code = textController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  _processBarcode(code);
                }
              },
              child: const Text('Look Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  void _showCatalogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Material(
              color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: ColorPalette.freshEmerald),
                        const SizedBox(width: 8),
                        const Text(
                          'Offline Grocery Catalog',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: offlineBarcodeCatalog.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final product = offlineBarcodeCatalog[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              product.effectiveImageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 44,
                                height: 44,
                                color: product.category.color.withValues(alpha: 0.2),
                                child: Icon(product.category.icon, color: product.category.color, size: 22),
                              ),
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            'SKU: ${product.barcode} • Shelf life: ${product.defaultShelfLifeDays} days',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(context).pop();
                            _processBarcode(product.barcode);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Preview / Fallback
          if (!kIsWeb)
            MobileScanner(
              controller: _controller,
              onDetect: _handleBarcodeDetect,
              errorBuilder: (context, error) {
                return _buildCameraErrorView(error.toString());
              },
            )
          else
            _buildCameraErrorView('Live camera not available'),

          // 2. Dark Vignette Viewfinder Reticle Overlay
          _buildScannerOverlay(),

          // 3. Top Action Bar: Back / Torch / Flip
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel / Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      tooltip: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Center Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Scan Barcode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  // Torch & Flip buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            color: _isTorchOn ? ColorPalette.warningAmber : Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Toggle Flashlight',
                          onPressed: () async {
                            await _controller.toggleTorch();
                            setState(() => _isTorchOn = !_isTorchOn);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 20),
                          tooltip: 'Switch Camera',
                          onPressed: () => _controller.switchCamera(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Controls: Instruction, Manual Entry, Catalog
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instruction text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.center_focus_strong_rounded, color: ColorPalette.freshEmerald, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Place the grocery barcode inside the box',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Manual & Catalog Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              backgroundColor: Colors.black.withValues(alpha: 0.55),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.keyboard_rounded, size: 18),
                            label: const Text('Enter Code', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: _showManualEntryDialog,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPalette.freshEmerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            label: const Text('Preset Catalog', style: TextStyle(fontWeight: FontWeight.w800)),
                            onPressed: _showCatalogSheet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: ColorPalette.freshEmerald),
                    SizedBox(height: 16),
                    Text(
                      'Identifying Product & Expiry...',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth * 0.78;
        const boxHeight = 220.0;
        final left = (constraints.maxWidth - boxWidth) / 2;
        final top = (constraints.maxHeight - boxHeight) / 2 - 30;

        return Stack(
          children: [
            // Dark Cutout Background
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    width: boxWidth,
                    height: boxHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Viewfinder Reticle Frame with glowing corner brackets
            Positioned(
              left: left,
              top: top,
              width: boxWidth,
              height: boxHeight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ColorPalette.freshEmerald.withValues(alpha: 0.6),
                    width: 2.0,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corner Highlights
                    ..._buildCornerMarkers(),

                    // Animated Laser Scanning Line
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Positioned(
                          top: _animController.value * (boxHeight - 4),
                          left: 4,
                          right: 4,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ColorPalette.freshEmerald.withValues(alpha: 0.0),
                                  ColorPalette.freshEmerald,
                                  ColorPalette.freshEmerald.withValues(alpha: 0.0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorPalette.freshEmerald.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCornerMarkers() {
    const size = 20.0;
    const thickness = 3.5;
    const radius = Radius.circular(16);
    const color = ColorPalette.freshEmerald;

    return [
      // Top-Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(topLeft: radius),
          ),
        ),
      ),
      // Top-Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(topRight: radius),
          ),
        ),
      ),
      // Bottom-Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomLeft: radius),
          ),
        ),
      ),
      // Bottom-Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomRight: radius),
          ),
        ),
      ),
    ];
  }

  Widget _buildCameraErrorView(String error) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorPalette.warningAmber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: ColorPalette.warningAmber,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Camera Not Ready',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please grant camera permission or use manual code entry below to look up any product.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.freshEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.keyboard_rounded),
              label: const Text('Enter Barcode Manually', style: TextStyle(fontWeight: FontWeight.w800)),
              onPressed: _showManualEntryDialog,
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive Modal Bottom Sheet shown when any product is captured
class _ProductCapturedModalSheet extends ConsumerStatefulWidget {
  final BarcodeProduct product;
  final void Function(String name, String location) onAddSuccess;

  const _ProductCapturedModalSheet({
    required this.product,
    required this.onAddSuccess,
  });

  @override
  ConsumerState<_ProductCapturedModalSheet> createState() => _ProductCapturedModalSheetState();
}

class _ProductCapturedModalSheetState extends ConsumerState<_ProductCapturedModalSheet> {
  late final TextEditingController _nameController;
  late FoodCategory _selectedCategory;
  late StorageLocation _selectedLocation;
  late DateTime _selectedExpiryDate;
  late double _quantity;
  late FoodUnit _unit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _selectedCategory = widget.product.category;
    _selectedLocation = widget.product.storageLocation;
    _selectedExpiryDate = widget.product.estimatedExpiryDate;
    _quantity = widget.product.defaultQuantity;
    _unit = widget.product.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(FoodCategory category) {
    setState(() {
      _selectedCategory = category;
      // Auto-recalculate expiry date if the user changes product category
      _selectedExpiryDate = ExpiryDateExtractor.estimateExpiryDate(
        category: category,
        foodName: _nameController.text,
      );
    });
  }

  Future<void> _pickCustomExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: ColorPalette.freshEmerald,
              primary: ColorPalette.freshEmerald,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedExpiryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final daysRemaining = _selectedExpiryDate.difference(DateTime.now()).inDays;
    final expiryFormatted = DateFormat('MMM d, yyyy').format(_selectedExpiryDate);
    final imageUrl = widget.product.effectiveImageUrl;

    return Container(
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
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
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
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title row with celebration badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorPalette.freshEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColorPalette.freshEmerald.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: ColorPalette.freshEmerald, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Product Captured! ✨',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: ColorPalette.freshEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Product Card: Auto-captured photo + Name + Category + Expiry
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auto-captured product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imageUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 76,
                          height: 76,
                          color: _selectedCategory.color.withValues(alpha: 0.2),
                          child: Icon(_selectedCategory.icon, color: _selectedCategory.color, size: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                              border: InputBorder.none,
                              hintText: 'Product Name',
                              suffixIcon: Icon(Icons.edit_rounded, size: 14, color: theme.colorScheme.primary),
                              suffixIconConstraints: const BoxConstraints(),
                            ),
                          ),
                          if (widget.product.brand != null && widget.product.brand!.isNotEmpty) ...[
                            Text(
                              'Brand: ${widget.product.brand}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'SKU / Barcode: ${widget.product.barcode}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? ColorPalette.darkTextTertiary : ColorPalette.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Category Selector Chips Row
              Text(
                'Product Category',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: FoodCategory.values.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = FoodCategory.values[index];
                    final isSelected = cat == _selectedCategory;
                    return InkWell(
                      onTap: () => _onCategoryChanged(cat),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? cat.color : cat.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? cat.color : cat.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 16,
                              color: isSelected ? Colors.white : cat.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : cat.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Auto-Calculated Expiry Info Card (Tap to customize date)
              InkWell(
                onTap: _pickCustomExpiryDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ColorPalette.freshEmerald.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_rounded, color: ColorPalette.freshEmerald, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auto-Calculated Expiry Date (Tap to adjust)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ColorPalette.freshEmerald),
                            ),
                            Text(
                              '$expiryFormatted (${daysRemaining > 0 ? "Expires in $daysRemaining days" : "Expires today"})',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_calendar_rounded, size: 18, color: ColorPalette.freshEmerald),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons: 1-Tap Add to Pantry & Edit in Full Form
              Row(
                children: [
                  // Edit in full form button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddEditFoodScreen(
                              initialItem: FoodItem(
                                id: '',
                                name: _nameController.text.trim().isNotEmpty
                                    ? _nameController.text.trim()
                                    : widget.product.name,
                                category: _selectedCategory,
                                purchaseDate: DateTime.now(),
                                expiryDate: _selectedExpiryDate,
                                remainingQuantity: _quantity,
                                unit: _unit,
                                storageLocation: _selectedLocation,
                                price: widget.product.defaultPrice,
                                minimumStock: widget.product.minimumStock,
                                barcode: widget.product.barcode,
                                imagePath: imageUrl,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Full Form', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 1-Tap Add to Pantry Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                      label: Text(
                        _isSaving ? 'Adding...' : 'Add to Inventory',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.freshEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              final name = _nameController.text.trim().isNotEmpty
                                  ? _nameController.text.trim()
                                  : 'Scanned Item (${widget.product.barcode})';

                              await ref.read(foodListControllerProvider.notifier).quickAddFood(
                                    name: name,
                                    quantity: _quantity,
                                    expiryDate: _selectedExpiryDate,
                                    category: _selectedCategory,
                                    unit: _unit,
                                    location: _selectedLocation,
                                    price: widget.product.defaultPrice,
                                    minStock: widget.product.minimumStock,
                                    barcode: widget.product.barcode,
                                    imagePath: imageUrl,
                                  );

                              if (mounted && context.mounted) {
                                Navigator.of(context).pop();
                                widget.onAddSuccess(name, _selectedLocation.label);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

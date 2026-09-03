import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/services/barcode_lookup_service.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_unit.dart';
import '../../domain/entities/storage_location.dart';
import '../providers/food_inventory_providers.dart';

/// Dedicated Barcode Scanner Screen with live camera preview, overlay reticle, duplicate detection, and offline catalog fallback
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  final ValueChanged<BarcodeProduct>? onProductSelected;

  const BarcodeScannerScreen({
    super.key,
    this.onProductSelected,
  });

  static Future<BarcodeProduct?> open(BuildContext context) async {
    return await Navigator.of(context).push<BarcodeProduct>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
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
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.qrCode,
      ],
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
        BarcodeProduct(
          barcode: cleanCode,
          name: '',
          category: FoodCategory.other,
          defaultQuantity: 1.0,
          unit: FoodUnit.pieces,
          storageLocation: StorageLocation.pantry,
          defaultShelfLifeDays: 30,
        );

    if (!mounted) return;

    if (widget.onProductSelected != null) {
      widget.onProductSelected!(resolvedProduct);
      Navigator.of(context).pop(resolvedProduct);
    } else {
      Navigator.of(context).pop(resolvedProduct);
    }
  }

  Future<void> _showDuplicateBarcodeDialog(FoodItem item, String barcode) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorPalette.warningAmber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: ColorPalette.warningAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Barcode In Pantry',
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
                'This grocery barcode ($barcode) is already in your pantry:',
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
                Navigator.of(context).pop();
                // Return product anyway to add another instance
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
                  Navigator.of(this.context).pop(product);
                } else {
                  Navigator.of(this.context).pop(product);
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
                Navigator.of(context).pop();
                Navigator.of(this.context).pop();
                this.context.push(RoutePaths.foodDetailPath(item.id));
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

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Enter Barcode Manually', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: TextField(
            controller: textController,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0),
            decoration: InputDecoration(
              labelText: 'Barcode SKU',
              hintText: 'e.g. 8906001020011',
              prefixIcon: const Icon(Icons.qr_code_2_rounded, color: ColorPalette.freshEmerald),
              filled: true,
              fillColor: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                  Navigator.of(context).pop();
                  _processBarcode(code);
                }
              },
              child: const Text('Lookup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: product.category.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(product.category.icon, color: product.category.color, size: 20),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            'SKU: ${product.barcode} • ${product.defaultQuantity.toStringAsFixed(0)} ${product.unit.label}',
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
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth * 0.78;
        final boxHeight = 220.0;
        final left = (constraints.maxWidth - boxWidth) / 2;
        final top = (constraints.maxHeight - boxHeight) / 2 - 30;

        return Stack(
          children: [
            // Dark surrounding cutout mask
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
                        final y = _animController.value * (boxHeight - 16);
                        return Positioned(
                          top: y,
                          left: 8,
                          right: 8,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  ColorPalette.freshEmerald,
                                  Color(0xFF34D399),
                                  ColorPalette.freshEmerald,
                                  Colors.transparent,
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
                Icons.videocam_off_rounded,
                color: ColorPalette.warningAmber,
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Camera Scanner Standby',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Camera permission is required to scan live barcodes. You can also enter the barcode manually or select from the offline catalog.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.freshEmerald,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.keyboard_rounded, color: Colors.white, size: 18),
                  label: const Text('Enter Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  onPressed: _showManualEntryDialog,
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text('Preset Catalog', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _showCatalogSheet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

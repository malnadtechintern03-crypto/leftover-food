import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/food_image_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../../shopping_list/presentation/widgets/add_edit_shopping_item_dialog.dart';
import '../../../waste_tracking/presentation/widgets/log_waste_dialog.dart';
import '../../domain/entities/food_item.dart';
import '../providers/food_detail_controller.dart';
import '../providers/food_list_controller.dart';
import '../widgets/consume_quantity_dialog.dart';
import '../widgets/expiry_countdown_badge.dart';

/// Screen presenting in-depth grocery information, storage location, price, and status controls
class FoodDetailScreen extends ConsumerWidget {
  final String id;

  const FoodDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final itemAsync = ref.watch(foodDetailControllerProvider(id));
    final notifier = ref.read(foodDetailControllerProvider(id).notifier);
    final settings = ref.watch(settingsControllerProvider).valueOrNull;
    final warningDays = settings?.expiryWarningDays ?? 2;

    return itemAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: ColorPalette.primaryGreen),
        ),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateView(
          message: err.toString(),
          onRetry: () => notifier.loadItem(),
        ),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'Grocery item not found or has been deleted.',
                style: theme.textTheme.titleMedium,
              ),
            ),
          );
        }

        final status = item.getStatus(warningDays: warningDays);
        final progress = item.freshnessProgress().clamp(0.0, 1.0);
        final isLow = item.isLowStock();

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Dynamic Sliver App Bar with Image or Category Banner
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeaderBanner(context, item, isDark),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: item.isFavorite ? ColorPalette.warningAmber : null,
                    ),
                    tooltip: item.isFavorite ? 'Unfavorite' : 'Favorite',
                    onPressed: () {
                      ref.read(foodListControllerProvider.notifier).toggleFavorite(item.id);
                      notifier.loadItem();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Edit details',
                    onPressed: () {
                      context.push(RoutePaths.editFoodPath(item.id));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Delete item',
                    onPressed: () async {
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Delete Grocery Item?',
                        message:
                            'Are you sure you want to remove "${item.name}" from your grocery pantry?',
                        confirmLabel: 'Delete',
                        isDestructive: true,
                        icon: Icons.delete_forever_rounded,
                      );

                      if (confirmed == true && context.mounted) {
                        await notifier.delete();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${item.name}.'),
                              backgroundColor: ColorPalette.expiredRed,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          context.pop();
                        }
                      }
                    },
                  ),
                ],
              ),

              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge & Category & Storage Location
                      Row(
                        children: [
                          ExpiryCountdownBadge(
                            expiryDate: item.expiryDate,
                            status: status,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: item.category.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(item.category.icon,
                                    size: 13, color: item.category.color),
                                const SizedBox(width: 5),
                                Text(
                                  item.category.label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: item.category.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: item.storageLocation.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(item.storageLocation.icon,
                                    size: 13, color: item.storageLocation.color),
                                const SizedBox(width: 5),
                                Text(
                                  item.storageLocation.label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: item.storageLocation.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Food Item Name & Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                decoration: item.isConsumed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (item.price != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              '₹${item.price!.toStringAsFixed(item.price!.truncateToDouble() == item.price ? 0 : 2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: ColorPalette.freshEmerald,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Low-Stock alert card
                      if (isLow && !item.isConsumed) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ColorPalette.warningAmber.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ColorPalette.warningAmber.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: ColorPalette.warningAmber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Low Stock Warning: Only ${item.remainingQuantity.toStringAsFixed(0)} ${item.unit.abbreviation} remaining (Min: ${item.minimumStock?.toStringAsFixed(0)}).',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  AddEditShoppingItemDialog.show(
                                    context,
                                    prefillName: item.name,
                                    prefillCategory: item.category,
                                    prefillQuantity: item.minimumStock ?? 1.0,
                                    prefillUnit: item.unit,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorPalette.warningAmber,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  '+ Add to List',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Quantity & Freshness Progress Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ColorPalette.darkCard
                              : ColorPalette.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? ColorPalette.darkBorder
                                : ColorPalette.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Remaining Quantity',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? ColorPalette.darkTextSecondary
                                            : ColorPalette.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.remainingQuantity.toStringAsFixed(item.remainingQuantity.truncateToDouble() == item.remainingQuantity ? 0 : 1)} ${item.unit.displayName}',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: ColorPalette.freshEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!item.isConsumed)
                                  AppButton(
                                    label: 'Log Used',
                                    icon: Icons.check_circle_outline_rounded,
                                    height: 40,
                                    onPressed: () async {
                                      final qty =
                                          await ConsumeQuantityDialog.show(
                                              context, item);
                                      if (qty != null) {
                                        await notifier.consume(qty);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Logged $qty ${item.unit.abbreviation} used!',
                                              ),
                                              backgroundColor:
                                                  ColorPalette.freshEmeraldDark,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Shelf-life Timeline',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toInt()}% elapsed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: status.color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: isDark
                                        ? ColorPalette.darkSurface
                                        : ColorPalette.lightSurface,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        status.color),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Storage & Date Details Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ColorPalette.darkCard
                              : ColorPalette.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? ColorPalette.darkBorder
                                : ColorPalette.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              context,
                              icon: Icons.kitchen_rounded,
                              label: 'Storage Location',
                              value: item.storageLocation.label,
                              iconColor: item.storageLocation.color,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              context,
                              icon: Icons.calendar_today_rounded,
                              label: 'Purchase Date',
                              value:
                                  '${DateFormatter.formatDate(item.purchaseDate)} (${item.daysStored()} days ago)',
                              iconColor: ColorPalette.freshEmerald,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              context,
                              icon: Icons.event_busy_rounded,
                              label: 'Best Before / Expiry Date',
                              value: DateFormatter.formatDate(item.expiryDate),
                              iconColor: ColorPalette.warningAmber,
                            ),
                            if (item.barcode != null && item.barcode!.isNotEmpty) ...[
                              const Divider(height: 24),
                              _buildInfoRow(
                                context,
                                icon: Icons.qr_code_2_rounded,
                                label: 'Barcode SKU',
                                value: item.barcode!,
                                iconColor: const Color(0xFF0284C7),
                              ),
                            ],
                            if (item.isRecurring) ...[
                              const Divider(height: 24),
                              _buildInfoRow(
                                context,
                                icon: Icons.repeat_rounded,
                                label: 'Recurring Grocery Schedule',
                                value: 'Every ${item.recurringIntervalDays ?? 7} days',
                                iconColor: const Color(0xFF8B5CF6),
                              ),
                            ],
                            if (item.notes != null &&
                                item.notes!.trim().isNotEmpty) ...[
                              const Divider(height: 24),
                              _buildInfoRow(
                                context,
                                icon: Icons.notes_rounded,
                                label: 'Storage & Pantry Notes',
                                value: item.notes!,
                                iconColor: ColorPalette.categoryDrinks,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      if (!item.isConsumed) ...[
                        AppButton(
                          label: 'Extend Expiry Date (Preserve)',
                          icon: Icons.ac_unit_rounded,
                          variant: ButtonVariant.secondary,
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: item.expiryDate
                                  .add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              await notifier.extendExpiry(picked);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Expiry date extended to ${DateFormatter.formatDate(picked)}!',
                                    ),
                                    backgroundColor:
                                        ColorPalette.primaryGreenDark,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => LogWasteDialog.show(context, item),
                          icon: const Icon(Icons.delete_sweep_rounded, color: ColorPalette.sunsetCoral, size: 18),
                          label: const Text(
                            'Log as Discarded / Waste',
                            style: TextStyle(fontWeight: FontWeight.w700, color: ColorPalette.sunsetCoral),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(color: ColorPalette.sunsetCoral.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner(
      BuildContext context, FoodItem item, bool isDark) {
    if (item.imagePath != null && !kIsWeb) {
      final file = File(item.imagePath!);
      if (file.existsSync()) {
        final formattedQty =
            '${item.remainingQuantity.toStringAsFixed(item.remainingQuantity.truncateToDouble() == item.remainingQuantity ? 0 : 1)} ${item.unit.abbreviation} • ${item.category.label}';

        return GestureDetector(
          onTap: () => FullScreenImageViewer.show(
            context,
            imagePath: item.imagePath!,
            title: item.name,
            subtitle: formattedQty,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(file, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                right: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
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
            ],
          ),
        );
      }
    }

    final photoUrl = FoodImageHelper.getEffectiveImageUrl(item.name, item.category);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          photoUrl,
          fit: BoxFit.cover,
          cacheWidth: 800,
          cacheHeight: 450,
          errorBuilder: (context, error, stackTrace) => _buildCategoryBannerFallback(item),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBannerFallback(FoodItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.category.color.withValues(alpha: 0.85),
            item.category.color.withValues(alpha: 0.45),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          item.category.icon,
          size: 80,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? ColorPalette.darkTextSecondary
                      : ColorPalette.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

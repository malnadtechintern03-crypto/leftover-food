import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/utils/food_image_helper.dart';
import '../../../shopping_list/presentation/widgets/add_edit_shopping_item_dialog.dart';
import '../../../waste_tracking/presentation/widgets/log_waste_dialog.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_status.dart';
import '../providers/food_list_controller.dart';
import 'consume_quantity_dialog.dart';

/// Comprehensive, modern Grocery Item Card matching the Groceries design system
class FoodCard extends ConsumerWidget {
  final FoodItem item;
  final int warningDays;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final void Function(double consumedQuantity)? onConsume;
  final VoidCallback? onDelete;

  const FoodCard({
    super.key,
    required this.item,
    this.warningDays = 2,
    required this.onTap,
    this.onEdit,
    this.onConsume,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = item.getStatus(warningDays: warningDays);
    final days = item.daysUntilExpiry();
    final addedDateStr = DateFormat('MMM d, yyyy').format(item.purchaseDate);
    final expiryDateStr = DateFormat('MMM d, yyyy').format(item.expiryDate);
    final isLow = item.isLowStock();

    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isLow
              ? ColorPalette.warningAmber.withValues(alpha: 0.6)
              : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
          width: isLow ? 1.4 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Thumbnail Image + Name/Category/Location/Price + Star + Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grocery Thumbnail Image
                  FoodImageHelper.buildFoodImage(
                    item: item,
                    width: 58,
                    height: 58,
                    borderRadius: 14,
                    fit: BoxFit.cover,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),

                  // Name & Category Badge & Quantity & Storage Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  decoration: item.isConsumed ? TextDecoration.lineThrough : null,
                                  color: isDark
                                      ? ColorPalette.darkTextPrimary
                                      : ColorPalette.lightTextPrimary,
                                ),
                              ),
                            ),
                            if (item.price != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '₹${item.price!.toStringAsFixed(item.price!.truncateToDouble() == item.price ? 0 : 2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? ColorPalette.freshEmerald : ColorPalette.freshEmeraldDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Category Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.category.color.withValues(alpha: isDark ? 0.18 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: item.category.color,
                                ),
                              ),
                            ),
                            // Storage Location Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.storageLocation.color.withValues(alpha: isDark ? 0.18 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(item.storageLocation.icon, size: 10.5, color: item.storageLocation.color),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.storageLocation.label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: item.storageLocation.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity
                            Text(
                              '${item.remainingQuantity.toStringAsFixed(item.remainingQuantity.truncateToDouble() == item.remainingQuantity ? 0 : 1)} ${item.unit.abbreviation}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? ColorPalette.darkTextSecondary
                                    : ColorPalette.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Favorite Star Button
                  IconButton(
                    icon: Icon(
                      item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: item.isFavorite ? ColorPalette.warningAmber : (isDark ? Colors.white38 : Colors.black26),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.read(foodListControllerProvider.notifier).toggleFavorite(item.id);
                    },
                  ),
                  const SizedBox(width: 4),

                  // Three-Dot Popup Action Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                      ),
                    ),
                    color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                    onSelected: (value) async {
                      if (value == 'view') {
                        onTap();
                      } else if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'rescue') {
                        if (!item.isConsumed && onConsume != null) {
                          final qty = await ConsumeQuantityDialog.show(context, item);
                          if (qty != null) {
                            onConsume!(qty);
                          }
                        }
                      } else if (value == 'shopping') {
                        AddEditShoppingItemDialog.show(
                          context,
                          prefillName: item.name,
                          prefillCategory: item.category,
                          prefillQuantity: item.minimumStock ?? 1.0,
                          prefillUnit: item.unit,
                        );
                      } else if (value == 'waste') {
                        LogWasteDialog.show(context, item);
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Edit Item'),
                            ],
                          ),
                        ),
                      if (!item.isConsumed && onConsume != null)
                        const PopupMenuItem(
                          value: 'rescue',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 18, color: ColorPalette.freshEmerald),
                              SizedBox(width: 10),
                              Text('Mark as Rescued', style: TextStyle(color: ColorPalette.freshEmerald, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'shopping',
                        child: Row(
                          children: [
                            Icon(Icons.add_shopping_cart_rounded, size: 18, color: Color(0xFF0284C7)),
                            SizedBox(width: 10),
                            Text('Add to Shopping List', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'waste',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 18, color: ColorPalette.sunsetCoral),
                            SizedBox(width: 10),
                            Text('Log to Waste', style: TextStyle(color: ColorPalette.sunsetCoral, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: ColorPalette.expiredRed),
                              SizedBox(width: 10),
                              Text('Delete', style: TextStyle(color: ColorPalette.expiredRed)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Low-Stock Warning Strip (if quantity <= minStock)
              if (isLow && !item.isConsumed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorPalette.warningAmber.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ColorPalette.warningAmber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: ColorPalette.warningAmber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Low stock (Min: ${item.minimumStock?.toStringAsFixed(0)} ${item.unit.abbreviation})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ColorPalette.warningAmber),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          AddEditShoppingItemDialog.show(
                            context,
                            prefillName: item.name,
                            prefillCategory: item.category,
                            prefillQuantity: item.minimumStock ?? 1.0,
                            prefillUnit: item.unit,
                          );
                        },
                        child: const Text(
                          '+ Add to List',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
              ),
              const SizedBox(height: 8),

              // Bottom Row: Added Date, Expiry Date, and Status Pill
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Added: $addedDateStr',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? ColorPalette.darkTextTertiary : ColorPalette.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Best Before: $expiryDateStr',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Remaining Days Countdown Pill
                  _buildExpiryPill(days, status, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryPill(int days, FoodStatus status, bool isDark) {
    Color bg;
    Color text;
    String label;

    if (item.isConsumed) {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      text = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      label = 'Rescued';
    } else if (days < 0) {
      bg = isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2);
      text = const Color(0xFFE11D48);
      label = 'Expired';
    } else if (days == 0) {
      bg = isDark ? const Color(0xFF431407) : const Color(0xFFFFF1EE);
      text = const Color(0xFFE11D48);
      label = 'Expires today';
    } else if (days == 1) {
      bg = isDark ? const Color(0xFF382300) : const Color(0xFFFEF3C7);
      text = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      label = 'Expires tomorrow';
    } else {
      bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
      text = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      label = '$days days left';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }
}

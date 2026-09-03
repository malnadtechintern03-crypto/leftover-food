import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/utils/food_image_helper.dart';
import '../../../food_inventory/domain/entities/food_item.dart';
import '../../../food_inventory/domain/entities/food_status.dart';

class CalendarEventList extends StatelessWidget {
  final DateTime selectedDate;
  final List<FoodItem> items;
  final int warningDays;

  const CalendarEventList({
    super.key,
    required this.selectedDate,
    required this.items,
    required this.warningDays,
  });

  Color _getStatusColor(FoodStatus status, bool isConsumed) {
    if (isConsumed) return const Color(0xFF94A3B8);
    switch (status) {
      case FoodStatus.fresh:
        return ColorPalette.freshEmerald;
      case FoodStatus.expiringSoon:
        return ColorPalette.warningAmber;
      case FoodStatus.expired:
        return ColorPalette.expiredRed;
      case FoodStatus.consumed:
        return const Color(0xFF94A3B8);
    }
  }

  String _getStatusLabel(FoodStatus status, bool isConsumed) {
    if (isConsumed) return 'Used / Consumed';
    switch (status) {
      case FoodStatus.fresh:
        return 'Fresh';
      case FoodStatus.expiringSoon:
        return 'Expiring Soon';
      case FoodStatus.expired:
        return 'Expired';
      case FoodStatus.consumed:
        return 'Used / Consumed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formattedDate = DateFormat.yMMMMd().format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.event_note_rounded,
                size: 20,
                color: ColorPalette.freshEmerald,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Expiring on $formattedDate',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: items.isNotEmpty
                      ? (isDark
                          ? ColorPalette.freshEmerald.withValues(alpha: 0.18)
                          : ColorPalette.freshEmerald.withValues(alpha: 0.12))
                      : (isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: items.isNotEmpty
                        ? ColorPalette.freshEmerald.withValues(alpha: 0.4)
                        : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
                  ),
                ),
                child: Text(
                  '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: items.isNotEmpty
                        ? (isDark ? ColorPalette.freshEmerald : ColorPalette.freshEmeraldDark)
                        : (isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items List or Empty State
        if (items.isEmpty)
          _buildEmptyState(theme, isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemCard(context, item, theme, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? ColorPalette.freshEmerald.withValues(alpha: 0.12)
                    : ColorPalette.freshEmerald.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 32,
                color: ColorPalette.freshEmerald,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No grocery items expiring on this day',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select another date with indicators or add new grocery items.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    FoodItem item,
    ThemeData theme,
    bool isDark,
  ) {
    final status = item.getStatus(warningDays: warningDays);
    final statusColor = _getStatusColor(status, item.isConsumed);
    final statusText = _getStatusLabel(status, item.isConsumed);

    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      borderRadius: BorderRadius.circular(18),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: () => context.push(RoutePaths.foodDetailPath(item.id)),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image or Curated/Category Thumbnail
              FoodImageHelper.buildFoodImage(
                item: item,
                width: 56,
                height: 56,
                borderRadius: 14,
                isDark: isDark,
              ),

              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: item.isConsumed ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Category & Quantity
                    Row(
                      children: [
                        Text(
                          item.category.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.category.color,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ),
                        Text(
                          '${item.remainingQuantity.toStringAsFixed(item.remainingQuantity.truncateToDouble() == item.remainingQuantity ? 0 : 1)} ${item.unit.displayName}',
                          style: TextStyle(
                            fontSize: 12,
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

              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

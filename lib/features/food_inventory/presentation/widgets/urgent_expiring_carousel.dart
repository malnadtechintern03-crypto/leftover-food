import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/utils/food_image_helper.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_status.dart';

/// Horizontal "Urgent: Use Today" section matching Design 1
class UrgentExpiringCarousel extends StatelessWidget {
  final List<FoodItem> items;
  final int warningDays;
  final void Function(FoodItem item) onItemTap;
  final void Function(FoodItem item, double quantity)? onConsume;
  final VoidCallback? onViewAll;

  const UrgentExpiringCarousel({
    super.key,
    required this.items,
    this.warningDays = 2,
    required this.onItemTap,
    this.onConsume,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    // Filter active items that are expiring today, soon, or expired
    final urgentItems = items.where((item) {
      if (item.isConsumed) return false;
      final status = item.getStatus(warningDays: warningDays);
      return status == FoodStatus.expiringSoon || status == FoodStatus.expired;
    }).toList();

    if (urgentItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: "Urgent: Use Today" & "View all"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Urgent: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: ColorPalette.sunsetCoral,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: 'Use Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? ColorPalette.darkTextPrimary
                            : ColorPalette.lightTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onViewAll != null)
                InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7), // Clean vibrant link blue
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal List of Food Cards
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: urgentItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = urgentItems[index];
              return _buildUrgentCard(context, item, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentCard(
    BuildContext context,
    FoodItem item,
    bool isDark,
  ) {
    final days = item.daysUntilExpiry();
    final String expiryText = days < 0
        ? 'Expired'
        : (days == 0 ? 'Expires today' : (days == 1 ? 'Expires tomorrow' : '$days days left'));

    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? ColorPalette.darkBorder
              : ColorPalette.lightBorder,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onItemTap(item),
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Image Thumbnail
              FoodImageHelper.buildFoodImage(
                item: item,
                width: double.infinity,
                height: 85,
                borderRadius: 14,
                fit: BoxFit.cover,
                isDark: isDark,
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark
                      ? ColorPalette.darkTextPrimary
                      : ColorPalette.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),

              // Quantity
              Text(
                '${item.remainingQuantity.toStringAsFixed(item.remainingQuantity.truncateToDouble() == item.remainingQuantity ? 0 : 1)} ${item.unit.abbreviation}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? ColorPalette.darkTextSecondary
                      : ColorPalette.lightTextSecondary,
                ),
              ),
              const Spacer(),

              // Expiry Label Tag (Red/coral for urgency)
              Text(
                expiryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.sunsetCoral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

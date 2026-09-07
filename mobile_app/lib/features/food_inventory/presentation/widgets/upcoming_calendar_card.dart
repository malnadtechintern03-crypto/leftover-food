import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../food_inventory/domain/entities/food_item.dart';
import '../../../food_inventory/domain/entities/food_status.dart';

class UpcomingCalendarCard extends StatelessWidget {
  final List<FoodItem> items;
  final int warningDays;
  final VoidCallback onViewCalendar;

  const UpcomingCalendarCard({
    super.key,
    required this.items,
    required this.warningDays,
    required this.onViewCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter active items that are expiring soon or today (up to 3 items)
    final upcomingItems = items.where((item) {
      if (item.isConsumed) return false;
      final status = item.getStatus(warningDays: warningDays);
      return status == FoodStatus.expiringSoon || status == FoodStatus.expired;
    }).take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? ColorPalette.freshEmerald.withValues(alpha: 0.3)
              : ColorPalette.freshEmerald.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorPalette.freshEmerald.withValues(alpha: 0.18)
                        : ColorPalette.freshEmerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: ColorPalette.freshEmerald,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Expiries',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Tracked on Expiry Calendar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? ColorPalette.darkTextSecondary
                              : ColorPalette.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onViewCalendar,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Calendar',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? ColorPalette.freshEmerald
                                : ColorPalette.freshEmeraldDark,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark
                              ? ColorPalette.freshEmerald
                              : ColorPalette.freshEmeraldDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
          ),

          // Content preview
          if (upcomingItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: ColorPalette.freshEmerald,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No urgent expirations in the next few days!',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: upcomingItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = upcomingItems[index];
                final status = item.getStatus(warningDays: warningDays);
                final isExpired = status == FoodStatus.expired;
                final days = item.daysUntilExpiry();

                String timeText;
                Color statusColor;

                if (isExpired) {
                  timeText = 'Expired';
                  statusColor = ColorPalette.expiredRed;
                } else if (days == 0) {
                  timeText = 'Expires Today';
                  statusColor = ColorPalette.warningAmber;
                } else if (days == 1) {
                  timeText = 'Expires Tomorrow';
                  statusColor = ColorPalette.warningAmber;
                } else {
                  timeText = 'Expires in $days days';
                  statusColor = ColorPalette.warningAmber;
                }

                return Row(
                  children: [
                    Icon(
                      item.category.icon,
                      size: 16,
                      color: item.category.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

          // Bottom Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Material(
              color: isDark
                  ? ColorPalette.freshEmerald.withValues(alpha: 0.12)
                  : ColorPalette.freshEmerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onViewCalendar,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: ColorPalette.freshEmerald,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View Full Expiry Calendar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? ColorPalette.freshEmerald
                                : ColorPalette.freshEmeraldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

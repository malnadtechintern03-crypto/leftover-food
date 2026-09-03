import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../domain/entities/food_stats.dart';

/// 4-Column Quick Status Metric Grid matching Design 1:
/// - Expiring Soon (⌛)
/// - Expires Today (🔥)
/// - Expired (🚫)
/// - Rescued (🍃)
class StatusMetricGrid extends StatelessWidget {
  final FoodStats stats;
  final void Function(int index)? onCardTap;

  const StatusMetricGrid({
    super.key,
    required this.stats,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Expiring Soon (⌛)
          Expanded(
            child: _buildMetricCard(
              context,
              icon: Icons.hourglass_top_rounded,
              title: 'Expiring Soon',
              count: stats.expiringSoon,
              bgColor: isDark
                  ? ColorPalette.cardExpiringSoonDarkBg
                  : ColorPalette.cardExpiringSoonBg,
              accentColor: const Color(0xFFD97706),
              countColor: isDark
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFFB45309),
              onTap: () => onCardTap?.call(1),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Expires Today (🔥)
          Expanded(
            child: _buildMetricCard(
              context,
              icon: Icons.local_fire_department_rounded,
              title: 'Expires Today',
              count: stats.expiresToday,
              bgColor: isDark
                  ? ColorPalette.cardExpiresTodayDarkBg
                  : ColorPalette.cardExpiresTodayBg,
              accentColor: const Color(0xFFEA580C),
              countColor: const Color(0xFFE11D48),
              onTap: () => onCardTap?.call(2),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Expired (🚫)
          Expanded(
            child: _buildMetricCard(
              context,
              icon: Icons.cancel_outlined,
              title: 'Expired',
              count: stats.expired,
              bgColor: isDark
                  ? ColorPalette.cardExpiredDarkBg
                  : ColorPalette.cardExpiredBg,
              accentColor: const Color(0xFFE11D48),
              countColor: const Color(0xFFE11D48),
              onTap: () => onCardTap?.call(3),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Rescued (🍃)
          Expanded(
            child: _buildMetricCard(
              context,
              icon: Icons.eco_rounded,
              title: 'Rescued',
              count: stats.totalConsumed,
              bgColor: isDark
                  ? ColorPalette.cardRescuedDarkBg
                  : ColorPalette.cardRescuedBg,
              accentColor: const Color(0xFF059669),
              countColor: isDark
                  ? const Color(0xFF34D399)
                  : const Color(0xFF059669),
              onTap: () => onCardTap?.call(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required Color bgColor,
    required Color accentColor,
    required Color countColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Icon(
                icon,
                size: 20,
                color: accentColor,
              ),
              const SizedBox(height: 6),

              // Title (2 lines or 1 line)
              SizedBox(
                height: 26,
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? ColorPalette.darkTextSecondary
                          : const Color(0xFF4B5563),
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Count Value
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: countColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

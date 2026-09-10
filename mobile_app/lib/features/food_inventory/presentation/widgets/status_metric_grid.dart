import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../domain/entities/food_stats.dart';

/// 6-Metric Overview + 4 Quick Action Cards matching the Universal Expiration Reminder spec:
/// Metrics:
/// 1. Total products
/// 2. Expiring today
/// 3. Expiring within 7 days
/// 4. Expiring within 30 days
/// 5. Expired products
/// 6. Products without expiration date
/// Quick Action Cards:
/// - Expiring Soon, Expired, Safe, Add Product
class StatusMetricGrid extends StatelessWidget {
  final FoodStats stats;
  final void Function(int index)? onCardTap;
  final VoidCallback? onAddProduct;
  final VoidCallback? onOpenAlerts;
  final void Function(String filterKey)? onFilterTap;

  const StatusMetricGrid({
    super.key,
    required this.stats,
    this.onCardTap,
    this.onAddProduct,
    this.onOpenAlerts,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 6-Metric Overview Section
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Total Products',
                  count: stats.totalProducts,
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF6366F1),
                  bgColor: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                  onTap: () => onFilterTap?.call('all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Expiring Today',
                  count: stats.expiresToday,
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFEA580C),
                  bgColor: isDark ? const Color(0xFF431407) : const Color(0xFFFFF1EE),
                  onTap: () => onFilterTap?.call('today'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Expired',
                  count: stats.expired,
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFE11D48),
                  bgColor: isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2),
                  onTap: () => onFilterTap?.call('expired'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Within 7 Days',
                  count: stats.expiringWithin7Days,
                  icon: Icons.calendar_view_week_rounded,
                  color: const Color(0xFFD97706),
                  bgColor: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                  onTap: () => onFilterTap?.call('7days'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Within 30 Days',
                  count: stats.expiringWithin30Days,
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF0284C7),
                  bgColor: isDark ? const Color(0xFF082F49) : const Color(0xFFE0F2FE),
                  onTap: () => onFilterTap?.call('30days'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'No Expiry Date',
                  count: stats.noExpiryDate,
                  icon: Icons.all_inclusive_rounded,
                  color: const Color(0xFF64748B),
                  bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  onTap: () => onFilterTap?.call('no_expiry'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4 Quick-Action Cards
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  label: 'Expiring Soon',
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFD97706),
                  onTap: () {
                    onCardTap?.call(1);
                    onFilterTap?.call('expiring_soon');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionCard(
                  context,
                  label: 'Expired',
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFE11D48),
                  onTap: () {
                    onCardTap?.call(2);
                    onFilterTap?.call('expired');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionCard(
                  context,
                  label: 'Safe Products',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF059669),
                  onTap: () {
                    onCardTap?.call(0);
                    onFilterTap?.call('safe');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionCard(
                  context,
                  label: '+ Add Product',
                  icon: Icons.add_rounded,
                  color: ColorPalette.freshEmerald,
                  isPrimary: true,
                  onTap: () => onAddProduct?.call(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isPrimary
          ? color
          : (isDark ? ColorPalette.darkCard : ColorPalette.lightCard),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPrimary
              ? Colors.transparent
              : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : color,
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isPrimary
                        ? Colors.white
                        : (isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary),
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


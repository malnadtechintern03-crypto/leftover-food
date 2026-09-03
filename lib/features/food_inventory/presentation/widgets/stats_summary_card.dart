import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../domain/entities/food_stats.dart';

/// Ultra-Modern Glassmorphic Bento Dashboard with Cyber Aurora Freshness Gauge
class StatsSummaryCard extends StatelessWidget {
  final FoodStats stats;
  final void Function(int tabIndex)? onCardTap;

  const StatsSummaryCard({
    super.key,
    required this.stats,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate freshness health score percentage (0-100)
    final total = stats.totalActive;
    final urgent = stats.expiringSoon + stats.expired;
    final freshCount = (total - urgent).clamp(0, total);
    final healthPercentage = total == 0 ? 100 : ((freshCount / total) * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Hero Active Tile + Radial Freshness Dial
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bento 1: Large Active Leftovers Tile with Aurora Glow
              Expanded(
                flex: 6,
                child: _buildHeroActiveTile(context, isDark, healthPercentage),
              ),
              const SizedBox(width: 12),

              // Bento 2 & 3: Stacked Urgency & Saved Tiles
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildCompactBentoTile(
                      context,
                      isDark: isDark,
                      title: 'Expiring Soon',
                      subtitle: 'Needs eating',
                      count: stats.expiringSoon,
                      icon: Icons.hourglass_bottom_rounded,
                      accentColor: stats.expiringSoon > 0
                          ? ColorPalette.warningAmber
                          : ColorPalette.electricMint,
                      isAlert: stats.expiringSoon > 0,
                      onTap: () => onCardTap?.call(1),
                    ),
                    const SizedBox(height: 10),
                    _buildCompactBentoTile(
                      context,
                      isDark: isDark,
                      title: 'Food Rescued',
                      subtitle: 'Zero waste',
                      count: stats.totalConsumed,
                      icon: Icons.eco_rounded,
                      accentColor: ColorPalette.electricMint,
                      isAlert: false,
                      onTap: () => onCardTap?.call(0),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bento 4: Expired Action Banner if any expired items exist
          if (stats.expired > 0) ...[
            const SizedBox(height: 10),
            Material(
              color: isDark
                  ? ColorPalette.expiredRedDarkBg.withValues(alpha: 0.7)
                  : ColorPalette.expiredRedBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: ColorPalette.sunsetCoral.withValues(alpha: 0.7),
                  width: 1.3,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onCardTap?.call(3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ColorPalette.sunsetCoral.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.dangerous_outlined,
                          size: 16,
                          color: ColorPalette.sunsetCoral,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${stats.expired} item(s) past expiration. Tap to review & clear.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? ColorPalette.darkTextPrimary
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: ColorPalette.sunsetCoral,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroActiveTile(BuildContext context, bool isDark, int healthPercentage) {
    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark
              ? ColorPalette.primaryViolet.withValues(alpha: 0.45)
              : ColorPalette.lightBorderHighlight,
          width: 1.4,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onCardTap?.call(0),
        child: Container(
          height: 162,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorPalette.primaryViolet.withValues(alpha: 0.22),
                      ColorPalette.darkCard,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorPalette.primaryVioletLight.withValues(alpha: 0.7),
                      ColorPalette.lightCard,
                    ],
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Category Icon & Live Health Dial
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ColorPalette.auroraGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.primaryViolet.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.kitchen_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),

                  // Mini Freshness Health Gauge
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CustomPaint(
                          painter: _RadialFreshnessPainter(
                            percentage: healthPercentage / 100,
                            trackColor: isDark
                                ? ColorPalette.darkSurfaceHighlight
                                : ColorPalette.lightSurface,
                            progressColor: healthPercentage > 70
                                ? ColorPalette.electricMint
                                : (healthPercentage > 40
                                    ? ColorPalette.warningAmber
                                    : ColorPalette.sunsetCoral),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$healthPercentage%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: healthPercentage > 70
                              ? (isDark ? ColorPalette.electricMint : ColorPalette.pistachioGreenDark)
                              : (healthPercentage > 40
                                  ? ColorPalette.warningAmber
                                  : ColorPalette.sunsetCoral),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Middle: Count & Label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.totalActive}',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -1.2,
                      color: isDark
                          ? ColorPalette.darkTextPrimary
                          : ColorPalette.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Active Leftovers',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? ColorPalette.darkTextSecondary
                          : ColorPalette.lightTextSecondary,
                    ),
                  ),
                ],
              ),

              // Bottom Status line
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: ColorPalette.electricMint,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      stats.totalActive == 0
                          ? 'All fresh & organized'
                          : '${(stats.totalActive - stats.expired).clamp(0, stats.totalActive)} fresh in pantry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? ColorPalette.electricMint
                            : ColorPalette.pistachioGreenDark,
                      ),
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

  Widget _buildCompactBentoTile(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color accentColor,
    required bool isAlert,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isAlert
              ? accentColor.withValues(alpha: 0.7)
              : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
          width: isAlert ? 1.4 : 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: isAlert
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: isDark ? 0.22 : 0.10),
                      isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? ColorPalette.darkTextPrimary
                            : ColorPalette.lightTextPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? ColorPalette.darkTextSecondary
                            : ColorPalette.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter for the circular Freshness Dial Gauge
class _RadialFreshnessPainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;

  _RadialFreshnessPainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialFreshnessPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

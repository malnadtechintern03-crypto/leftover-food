import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../domain/entities/food_stats.dart';

/// Hero Pantry Overview Card matching Design 1
/// Shows total items in pantry & circular "72% Fresh" gauge with lush produce background
class PantryHeroCard extends StatelessWidget {
  final FoodStats stats;
  final VoidCallback? onTap;

  const PantryHeroCard({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = stats.totalActive;
    final freshPercentage = stats.freshPercentage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? const Color(0xFF063524) : const Color(0xFF0F3B2C),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF064E3B)).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background lush food image
                Positioned.fill(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    cacheHeight: 300,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF064E3B),
                            Color(0xFF047857),
                            Color(0xFF022C22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Gradient Overlay for pristine text contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.40),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),

                // Subtle Radial Ambient Glow
                Positioned(
                  top: -20,
                  left: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorPalette.freshEmerald.withValues(alpha: 0.25),
                    ),
                  ),
                ),

                // Main Content (Row: Total items on left, Circular Gauge on right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Count & Pantry Label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$total',
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Items in your pantry',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right: Circular Gauge "72% Fresh"
                      _buildFreshnessGauge(freshPercentage),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreshnessGauge(int percentage) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom Circular Progress Ring
          CustomPaint(
            size: const Size(90, 90),
            painter: _HeroDialPainter(
              percentage: (percentage / 100).clamp(0.0, 1.0),
              trackColor: Colors.white.withValues(alpha: 0.22),
              progressColor: Colors.white,
              strokeWidth: 5.5,
            ),
          ),

          // Percentage & "Fresh" label in center
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Fresh',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for the crisp white ring progress dial in the Hero Card
class _HeroDialPainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _HeroDialPainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroDialPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

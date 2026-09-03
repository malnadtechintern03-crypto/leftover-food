import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';

/// Modal bottom sheet displaying helpful leftover preservation and waste reduction tips
class FoodTipsSheet extends StatelessWidget {
  const FoodTipsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FoodTipsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tips = [
      (
        icon: Icons.inventory_2_outlined,
        title: 'FIFO (First In, First Out)',
        desc: 'Place newer grocery packages at the back and bring open or older packs forward so they get used first.',
        color: ColorPalette.freshEmerald,
      ),
      (
        icon: Icons.lock_clock_outlined,
        title: 'Airtight Pantry Jars',
        desc: 'Store grains, pulses, and flours in sealed glass jars to prevent moisture, humidity, and pests.',
        color: ColorPalette.categoryGrains,
      ),
      (
        icon: Icons.wb_shade_rounded,
        title: 'Protect Spices & Seasonings',
        desc: 'Keep whole and ground spices in a cool, dry cupboard away from stovetop heat to retain maximum aroma.',
        color: ColorPalette.categorySpices,
      ),
      (
        icon: Icons.opacity_rounded,
        title: 'Store Cooking Oils Safely',
        desc: 'Shield olive and cooking oils from direct sunlight and heat to prevent oxidation and maintain fresh taste.',
        color: ColorPalette.categoryOils,
      ),
      (
        icon: Icons.kitchen_rounded,
        title: 'Optimal Dairy Storage',
        desc: 'Store milk, butter, and yogurt on middle refrigerator shelves where temperature is consistent, not in door racks.',
        color: ColorPalette.categoryDairy,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? ColorPalette.freshGreenDarkBg
                          : ColorPalette.primaryGreenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tips_and_updates_rounded,
                      color: ColorPalette.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grocery & Pantry Storage Tips',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Smart habits to prolong shelf life and reduce waste',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? ColorPalette.darkTextSecondary
                                : ColorPalette.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...tips.map((tip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? ColorPalette.darkSurface
                          : ColorPalette.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? ColorPalette.darkBorder
                            : ColorPalette.lightBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tip.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tip.icon,
                            color: tip.color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tip.desc,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? ColorPalette.darkTextSecondary
                                      : ColorPalette.lightTextSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}


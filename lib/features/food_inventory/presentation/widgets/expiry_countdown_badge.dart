import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/utils/expiry_calculator.dart';
import '../../domain/entities/food_status.dart';

/// Visual pill badge showing the remaining shelf-life days and urgency styling
class ExpiryCountdownBadge extends StatelessWidget {
  final DateTime expiryDate;
  final FoodStatus status;
  final bool isCompact;

  const ExpiryCountdownBadge({
    super.key,
    required this.expiryDate,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusText = ExpiryCalculator.getExpiryStatusText(expiryDate);

    Color bg;
    Color fg;

    switch (status) {
      case FoodStatus.fresh:
        bg = isDark ? ColorPalette.freshGreenDarkBg.withValues(alpha: 0.7) : ColorPalette.freshGreenBg;
        fg = isDark ? ColorPalette.electricMint : ColorPalette.pistachioGreenDark;
        break;
      case FoodStatus.expiringSoon:
        bg = isDark ? ColorPalette.warningAmberDarkBg.withValues(alpha: 0.7) : ColorPalette.warningAmberBg;
        fg = ColorPalette.warningAmber;
        break;
      case FoodStatus.expired:
        bg = isDark ? ColorPalette.expiredRedDarkBg.withValues(alpha: 0.7) : ColorPalette.expiredRedBg;
        fg = ColorPalette.sunsetCoral;
        break;
      case FoodStatus.consumed:
        bg = isDark ? ColorPalette.consumedBlueDarkBg.withValues(alpha: 0.7) : ColorPalette.consumedBlueBg;
        fg = ColorPalette.primaryViolet;
        break;
    }

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.4), width: 0.9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

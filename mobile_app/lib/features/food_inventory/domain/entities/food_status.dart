import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';

/// Computed freshness / expiry / urgency status of a product
enum FoodStatus {
  fresh('Safe', Icons.check_circle_outline_rounded, ColorPalette.freshGreen, ColorPalette.freshGreenBg),
  expiringSoon('Expiring Soon', Icons.warning_amber_rounded, ColorPalette.warningAmber, ColorPalette.warningAmberBg),
  expired('Expired', Icons.dangerous_outlined, ColorPalette.expiredRed, ColorPalette.expiredRedBg),
  noExpiry('No Expiry Date', Icons.all_inclusive_rounded, Color(0xFF6366F1), Color(0xFFEEF2FF)),
  consumed('Used / Rescued', Icons.task_alt_rounded, ColorPalette.consumedBlue, ColorPalette.consumedBlueBg);

  final String label;
  final IconData icon;
  final Color color;
  final Color lightBgColor;

  const FoodStatus(this.label, this.icon, this.color, this.lightBgColor);

  /// Convenient alias matching the "Safe" naming
  static const FoodStatus safe = FoodStatus.fresh;
}


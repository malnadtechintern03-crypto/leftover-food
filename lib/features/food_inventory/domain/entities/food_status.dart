import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';

/// Computed freshness / urgency status of a food item
enum FoodStatus {
  fresh('Fresh', Icons.check_circle_outline_rounded, ColorPalette.freshGreen, ColorPalette.freshGreenBg),
  expiringSoon('Expiring Soon', Icons.warning_amber_rounded, ColorPalette.warningAmber, ColorPalette.warningAmberBg),
  expired('Expired', Icons.dangerous_outlined, ColorPalette.expiredRed, ColorPalette.expiredRedBg),
  consumed('Consumed', Icons.task_alt_rounded, ColorPalette.consumedBlue, ColorPalette.consumedBlueBg);

  final String label;
  final IconData icon;
  final Color color;
  final Color lightBgColor;

  const FoodStatus(this.label, this.icon, this.color, this.lightBgColor);
}

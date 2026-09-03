import 'package:flutter/material.dart';
import '../../app/theme/color_palette.dart';

enum ButtonVariant { primary, secondary, outline, danger }

/// Reusable styled button component
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bg = ColorPalette.primaryGreen;
        fg = Colors.white;
        break;
      case ButtonVariant.secondary:
        bg = isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface;
        fg = isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary;
        border = BorderSide(
          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
        );
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = ColorPalette.primaryGreen;
        border = const BorderSide(color: ColorPalette.primaryGreen, width: 1.5);
        break;
      case ButtonVariant.danger:
        bg = ColorPalette.expiredRed;
        fg = Colors.white;
        break;
    }

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          minimumSize: Size(width ?? 0, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

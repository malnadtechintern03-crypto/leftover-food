import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/food_item.dart';

/// Modal dialog enabling users to log consumption of all or part of a food item
class ConsumeQuantityDialog extends StatefulWidget {
  final FoodItem item;

  const ConsumeQuantityDialog({super.key, required this.item});

  static Future<double?> show(BuildContext context, FoodItem item) {
    return showDialog<double>(
      context: context,
      builder: (context) => ConsumeQuantityDialog(item: item),
    );
  }

  @override
  State<ConsumeQuantityDialog> createState() => _ConsumeQuantityDialogState();
}

class _ConsumeQuantityDialogState extends State<ConsumeQuantityDialog> {
  late double _consumeQuantity;

  @override
  void initState() {
    super.initState();
    // Default to consuming 1 unit or the total remaining
    _consumeQuantity = widget.item.remainingQuantity >= 1.0
        ? 1.0
        : widget.item.remainingQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;

    return AlertDialog(
      backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? ColorPalette.freshGreenDarkBg : ColorPalette.primaryGreenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: ColorPalette.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log Food Used',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much of "${item.name}" are you consuming?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorPalette.darkTextSecondary
                  : ColorPalette.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: _consumeQuantity > 0.5
                      ? () {
                          setState(() {
                            _consumeQuantity = (_consumeQuantity - 0.5)
                                .clamp(0.5, item.remainingQuantity);
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Column(
                  children: [
                    Text(
                      _consumeQuantity.toStringAsFixed(
                          _consumeQuantity.truncateToDouble() == _consumeQuantity ? 0 : 1),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ColorPalette.primaryGreen,
                      ),
                    ),
                    Text(
                      '${item.unit.displayName} (out of ${item.remainingQuantity.toStringAsFixed(item.remainingQuantity.truncateToDouble() == item.remainingQuantity ? 0 : 1)})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? ColorPalette.darkTextSecondary
                            : ColorPalette.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: _consumeQuantity < item.remainingQuantity
                      ? () {
                          setState(() {
                            _consumeQuantity = (_consumeQuantity + 0.5)
                                .clamp(0.5, item.remainingQuantity);
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _consumeQuantity = item.remainingQuantity;
                  });
                },
                child: const Text('Use All Remaining'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: ButtonVariant.secondary,
                  height: 44,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Confirm',
                  variant: ButtonVariant.primary,
                  height: 44,
                  onPressed: () => Navigator.of(context).pop(_consumeQuantity),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

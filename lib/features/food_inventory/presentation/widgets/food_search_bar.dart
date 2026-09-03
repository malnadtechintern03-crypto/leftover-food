import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../domain/entities/food_filter.dart';

/// Top search bar with integrated sort button, debounced queries, and Fresh & Modern styling
class FoodSearchBar extends StatefulWidget {
  final String initialQuery;
  final FoodSortOption currentSort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<FoodSortOption>? onSortChanged;
  final VoidCallback? onScanPressed;
  final bool showSortButton;
  final String hintText;

  const FoodSearchBar({
    super.key,
    required this.initialQuery,
    required this.currentSort,
    required this.onQueryChanged,
    this.onSortChanged,
    this.onScanPressed,
    this.showSortButton = true,
    this.hintText = 'Search groceries, items, or barcodes...',
  });

  @override
  State<FoodSearchBar> createState() => _FoodSearchBarState();
}

class _FoodSearchBarState extends State<FoodSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant FoodSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery &&
        _controller.text != widget.initialQuery) {
      _controller.text = widget.initialQuery;
    }
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 180), () {
      widget.onQueryChanged(text);
    });
    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showSortModal(BuildContext context) {
    if (widget.onSortChanged == null) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Sort Items By',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...FoodSortOption.values.map((option) {
                  final isSelected = option == widget.currentSort;
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? ColorPalette.freshEmerald
                          : (isDark
                              ? ColorPalette.darkTextSecondary
                              : ColorPalette.lightTextSecondary),
                    ),
                    title: Text(
                      option.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? ColorPalette.freshEmerald : ColorPalette.freshEmeraldDark)
                            : null,
                      ),
                    ),
                    onTap: () {
                      widget.onSortChanged!(option);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? ColorPalette.darkTextTertiary
                        : ColorPalette.lightTextTertiary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: ColorPalette.freshEmerald,
                    size: 22,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                          onPressed: () {
                            _controller.clear();
                            _debounceTimer?.cancel();
                            widget.onQueryChanged('');
                            setState(() {});
                          },
                        )
                      : (widget.onScanPressed != null
                          ? IconButton(
                              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                              color: ColorPalette.freshEmerald,
                              tooltip: 'Scan Barcode',
                              onPressed: widget.onScanPressed,
                            )
                          : null),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
          ),
          if (widget.showSortButton && widget.onSortChanged != null) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? ColorPalette.darkBorder
                      : ColorPalette.lightBorder,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: ColorPalette.freshEmerald,
                  size: 20,
                ),
                onPressed: () => _showSortModal(context),
                tooltip: 'Sort items',
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

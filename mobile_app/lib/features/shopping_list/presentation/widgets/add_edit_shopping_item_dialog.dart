import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../food_inventory/domain/entities/food_category.dart';
import '../../../food_inventory/domain/entities/food_unit.dart';
import '../../domain/entities/shopping_item.dart';
import '../providers/shopping_list_controller.dart';

class AddEditShoppingItemDialog extends ConsumerStatefulWidget {
  final ShoppingItem? initialItem;
  final String? prefillName;
  final FoodCategory? prefillCategory;
  final double? prefillQuantity;
  final FoodUnit? prefillUnit;

  const AddEditShoppingItemDialog({
    super.key,
    this.initialItem,
    this.prefillName,
    this.prefillCategory,
    this.prefillQuantity,
    this.prefillUnit,
  });

  static Future<void> show(
    BuildContext context, {
    ShoppingItem? initialItem,
    String? prefillName,
    FoodCategory? prefillCategory,
    double? prefillQuantity,
    FoodUnit? prefillUnit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditShoppingItemDialog(
        initialItem: initialItem,
        prefillName: prefillName,
        prefillCategory: prefillCategory,
        prefillQuantity: prefillQuantity,
        prefillUnit: prefillUnit,
      ),
    );
  }

  @override
  ConsumerState<AddEditShoppingItemDialog> createState() =>
      _AddEditShoppingItemDialogState();
}

class _AddEditShoppingItemDialogState
    extends ConsumerState<AddEditShoppingItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;

  late FoodCategory _category;
  late FoodUnit _unit;
  late ShoppingPriority _priority;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialItem?.name ?? widget.prefillName ?? '',
    );
    _quantityController = TextEditingController(
      text: (widget.initialItem?.quantity ?? widget.prefillQuantity ?? 1.0)
          .toStringAsFixed(
        (widget.initialItem?.quantity ?? widget.prefillQuantity ?? 1.0)
                    .truncateToDouble() ==
                (widget.initialItem?.quantity ?? widget.prefillQuantity ?? 1.0)
            ? 0
            : 1,
      ),
    );
    _category = widget.initialItem?.category ??
        widget.prefillCategory ??
        FoodCategory.other;
    _unit =
        widget.initialItem?.unit ?? widget.prefillUnit ?? FoodUnit.pieces;
    _priority = widget.initialItem?.priority ?? ShoppingPriority.medium;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    final qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;

    if (widget.initialItem != null) {
      final updated = widget.initialItem!.copyWith(
        name: name,
        quantity: qty,
        unit: _unit,
        category: _category,
        priority: _priority,
        updatedAt: DateTime.now(),
      );
      await ref
          .read(shoppingListControllerProvider.notifier)
          .updateItem(updated);
    } else {
      await ref.read(shoppingListControllerProvider.notifier).addItem(
            name: name,
            quantity: qty,
            unit: _unit,
            category: _category,
            priority: _priority,
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialItem != null
              ? 'Updated $name in shopping list'
              : 'Added $name to shopping list'),
          backgroundColor: ColorPalette.freshEmeraldDark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.initialItem != null
                  ? 'Edit Shopping Item'
                  : 'Add to Shopping List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: isDark
                    ? ColorPalette.darkTextPrimary
                    : ColorPalette.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: widget.initialItem == null,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ColorPalette.darkTextPrimary
                    : ColorPalette.lightTextPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g. Basmati Rice, Milk, Cooking Oil',
                filled: true,
                fillColor: isDark
                    ? ColorPalette.darkSurfaceHighlight
                    : ColorPalette.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.add_shopping_cart_rounded,
                    color: ColorPalette.freshEmerald),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      filled: true,
                      fillColor: isDark
                          ? ColorPalette.darkSurfaceHighlight
                          : ColorPalette.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<FoodUnit>(
                    initialValue: _unit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      filled: true,
                      fillColor: isDark
                          ? ColorPalette.darkSurfaceHighlight
                          : ColorPalette.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                    ),
                    items: FoodUnit.values.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(u.label,
                            style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<FoodCategory>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: isDark
                          ? ColorPalette.darkSurfaceHighlight
                          : ColorPalette.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                    ),
                    items: FoodCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(c.icon, size: 16, color: c.color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c.label,
                                style: const TextStyle(fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _category = v ?? _category),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<ShoppingPriority>(
                    initialValue: _priority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      filled: true,
                      fillColor: isDark
                          ? ColorPalette.darkSurfaceHighlight
                          : ColorPalette.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                    ),
                    items: ShoppingPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.label,
                            style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _priority = v ?? _priority),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded, color: Colors.white),
                label: Text(
                  widget.initialItem != null ? 'Save Changes' : 'Add to List',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.freshEmerald,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

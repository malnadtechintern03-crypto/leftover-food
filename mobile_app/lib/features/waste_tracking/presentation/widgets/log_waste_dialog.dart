import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../food_inventory/domain/entities/food_item.dart';
import '../../../food_inventory/presentation/providers/food_list_controller.dart';
import '../../domain/entities/waste_record.dart';
import '../providers/waste_controller.dart';

class LogWasteDialog extends ConsumerStatefulWidget {
  final FoodItem item;

  const LogWasteDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, FoodItem item) {
    return showDialog(
      context: context,
      builder: (context) => LogWasteDialog(item: item),
    );
  }

  @override
  ConsumerState<LogWasteDialog> createState() => _LogWasteDialogState();
}

class _LogWasteDialogState extends ConsumerState<LogWasteDialog> {
  WasteReason _reason = WasteReason.expiredBeforeUse;
  late final TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(
      text: widget.item.price != null
          ? widget.item.price!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  void _submit() async {
    final cost = double.tryParse(_costController.text.trim()) ?? widget.item.price ?? 0.0;

    final record = WasteRecord(
      id: const Uuid().v4(),
      foodItemId: widget.item.id,
      name: widget.item.name,
      category: widget.item.category,
      quantity: widget.item.remainingQuantity,
      unit: widget.item.unit,
      reason: _reason,
      cost: cost,
      wastedAt: DateTime.now(),
    );

    // 1. Record waste in SQLite
    await ref.read(wasteControllerProvider.notifier).logWaste(record);

    // 2. Delete item from active groceries
    await ref.read(foodListControllerProvider.notifier).deleteFood(widget.item.id);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged ${widget.item.name} to Waste Analytics'),
          backgroundColor: ColorPalette.sunsetCoralDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.delete_sweep_rounded, color: ColorPalette.expiredRed),
          const SizedBox(width: 8),
          const Text('Log Discarded Grocery'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${widget.item.name}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Quantity: ${widget.item.remainingQuantity.toStringAsFixed(1)} ${widget.item.unit.label}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Reason for Discard *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<WasteReason>(
              initialValue: _reason,
              isExpanded: true,
              items: WasteReason.values.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(r.label, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _reason = v ?? _reason),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Estimated Cost in ₹ (INR)',
                hintText: 'e.g. 80',
                prefixIcon: Center(
                  widthFactor: 1,
                  child: Text('₹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: ColorPalette.expiredRed),
          child: const Text('Log & Discard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

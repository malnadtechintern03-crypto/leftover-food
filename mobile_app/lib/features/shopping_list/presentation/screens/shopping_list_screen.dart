import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../food_inventory/domain/entities/storage_location.dart';
import '../../../food_inventory/presentation/providers/food_list_controller.dart';
import '../../domain/entities/shopping_item.dart';
import '../providers/shopping_list_controller.dart';
import '../widgets/add_edit_shopping_item_dialog.dart';

/// Smart Shopping List Screen with low-stock suggestions and pantry auto-import
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  void _showAddToPantryDialog(BuildContext context, WidgetRef ref, ShoppingItem item) {
    DateTime selectedExpiry = DateTime.now().add(const Duration(days: 30));
    StorageLocation selectedLocation = StorageLocation.pantry;
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add ${item.name} to Pantry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity: ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit.label}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Storage Location'),
                    trailing: DropdownButton<StorageLocation>(
                      value: selectedLocation,
                      items: StorageLocation.values.map((loc) {
                        return DropdownMenuItem(value: loc, child: Text(loc.label));
                      }).toList(),
                      onChanged: (v) => setState(() => selectedLocation = v ?? selectedLocation),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiry Date'),
                    subtitle: Text(
                      '${selectedExpiry.day}/${selectedExpiry.month}/${selectedExpiry.year}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: ColorPalette.freshEmerald),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today_rounded),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedExpiry,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) {
                          setState(() => selectedExpiry = picked);
                        }
                      },
                    ),
                  ),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price in ₹ (Optional)',
                      hintText: 'e.g. 150',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final price = double.tryParse(priceController.text.trim());
                    await ref.read(shoppingListControllerProvider.notifier).addToPantry(
                          shoppingItem: item,
                          expiryDate: selectedExpiry,
                          location: selectedLocation,
                          price: price,
                        );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${item.name} to your pantry!'),
                          backgroundColor: ColorPalette.freshEmeraldDark,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: ColorPalette.freshEmerald),
                  child: const Text('Add to Pantry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final shoppingState = ref.watch(shoppingListControllerProvider);
    final foodListState = ref.watch(foodListControllerProvider);

    // Find low-stock pantry items that are not already on the shopping list
    final lowStockItems = foodListState.items.valueOrNull?.where((i) => i.isLowStock()).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Smart Shopping List',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'Clear purchased items',
            onPressed: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Clear Purchased Items',
                message: 'Remove all purchased items from the shopping list?',
                confirmLabel: 'Clear',
              );
              if (confirmed == true) {
                await ref.read(shoppingListControllerProvider.notifier).clearPurchased();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEditShoppingItemDialog.show(context),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: ColorPalette.freshEmerald,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Search & Filters bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  TextField(
                    onChanged: (q) => ref.read(shoppingListControllerProvider.notifier).setSearchQuery(q),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search shopping list...',
                      filled: true,
                      fillColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: shoppingState.filterPurchased == null && shoppingState.filterPriority == null,
                          onSelected: (_) {
                            ref.read(shoppingListControllerProvider.notifier).setFilterPurchased(null);
                            ref.read(shoppingListControllerProvider.notifier).setFilterPriority(null);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Pending Only'),
                          selected: shoppingState.filterPurchased == false,
                          onSelected: (_) => ref.read(shoppingListControllerProvider.notifier).setFilterPurchased(false),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Purchased Only'),
                          selected: shoppingState.filterPurchased == true,
                          onSelected: (_) => ref.read(shoppingListControllerProvider.notifier).setFilterPurchased(true),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('High Priority 🔥'),
                          selected: shoppingState.filterPriority == ShoppingPriority.high,
                          onSelected: (_) => ref.read(shoppingListControllerProvider.notifier).setFilterPriority(ShoppingPriority.high),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Low-Stock Auto-Suggestions Banner
          if (lowStockItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorPalette.warningAmber.withValues(alpha: isDark ? 0.2 : 0.12),
                      ColorPalette.sunsetCoral.withValues(alpha: isDark ? 0.15 : 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ColorPalette.warningAmber.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notification_important_rounded, color: ColorPalette.warningAmber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Low Stock Suggestions (${lowStockItems.length})',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...lowStockItems.take(3).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} is running low (${item.remainingQuantity.toStringAsFixed(0)} ${item.unit.label} left)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                AddEditShoppingItemDialog.show(
                                  context,
                                  prefillName: item.name,
                                  prefillCategory: item.category,
                                  prefillQuantity: item.minimumStock ?? 1.0,
                                  prefillUnit: item.unit,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorPalette.warningAmber,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '+ Add to List',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Shopping Items List
          shoppingState.items.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Error loading shopping list: $err')),
            ),
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: ColorPalette.freshEmerald.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.checklist_rounded, size: 54, color: ColorPalette.freshEmerald),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your shopping list is empty',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap the button below to add groceries to buy',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isPurchased
                                ? ColorPalette.freshEmerald.withValues(alpha: 0.3)
                                : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Checkbox(
                            value: item.isPurchased,
                            activeColor: ColorPalette.freshEmerald,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            onChanged: (_) {
                              ref.read(shoppingListControllerProvider.notifier).togglePurchased(item.id);
                            },
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                                    color: item.isPurchased
                                        ? (isDark ? ColorPalette.darkTextTertiary : ColorPalette.lightTextTertiary)
                                        : (isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary),
                                  ),
                                ),
                              ),
                              if (item.priority == ShoppingPriority.high)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ColorPalette.sunsetCoral.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('High 🔥', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ColorPalette.sunsetCoral)),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit.label} • ${item.category.label}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.isPurchased)
                                TextButton.icon(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                  label: const Text('Add to Pantry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: ColorPalette.freshEmerald,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: () => _showAddToPantryDialog(context, ref, item),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => AddEditShoppingItemDialog.show(context, initialItem: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: ColorPalette.expiredRed),
                                onPressed: () {
                                  ref.read(shoppingListControllerProvider.notifier).deleteItem(item.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

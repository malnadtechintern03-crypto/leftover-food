import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../domain/entities/food_status.dart';
import '../../domain/entities/storage_location.dart';
import '../providers/food_list_controller.dart';
import '../widgets/category_filter_list.dart';
import '../widgets/food_card.dart';
import '../widgets/food_search_bar.dart';
import '../widgets/quick_add_dialog.dart';

/// Full Pantry Inventory Screen with Multi-criteria Filters: Category, Location, Status, Favorites & Low-Stock
class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listState = ref.watch(foodListControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? ColorPalette.darkBg : ColorPalette.lightBg,
      appBar: AppBar(
        title: Text(
          'My Pantry',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: ColorPalette.freshEmerald),
            tooltip: 'Scan Barcode',
            onPressed: () => context.push(RoutePaths.barcodeScanner),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: ColorPalette.freshEmerald),
            tooltip: 'Quick Add',
            onPressed: () => QuickAddDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded),
            tooltip: 'Load Sample Groceries',
            onPressed: () async {
              await ref.read(foodListControllerProvider.notifier).resetDemoData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Loaded 24 sample grocery items!'),
                    backgroundColor: ColorPalette.freshEmeraldDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
            onPressed: () {
              ref.read(foodListControllerProvider.notifier).loadItems();
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ColorPalette.freshEmerald,
          onRefresh: () async {
            await ref.read(foodListControllerProvider.notifier).loadItems();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Search Bar with Sort
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: FoodSearchBar(
                    initialQuery: listState.filter.searchQuery,
                    currentSort: listState.filter.sortOption,
                    onQueryChanged: (query) {
                      ref
                          .read(foodListControllerProvider.notifier)
                          .setSearchQuery(query);
                    },
                    onSortChanged: (sort) {
                      ref
                          .read(foodListControllerProvider.notifier)
                          .setSortOption(sort);
                    },
                  ),
                ),
              ),

              // 2. Category Filter Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CategoryFilterList(
                    selectedCategory: listState.filter.category,
                    onCategorySelected: (cat) {
                      ref
                          .read(foodListControllerProvider.notifier)
                          .setCategory(cat);
                    },
                  ),
                ),
              ),

              // 3. Storage Location Chips Carousel
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: StorageLocation.values.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final loc = StorageLocation.values[index];
                      final isSelected = listState.filter.storageLocation == loc;

                      return FilterChip(
                        avatar: Icon(loc.icon, size: 14, color: isSelected ? Colors.white : loc.color),
                        label: Text(loc.label),
                        selected: isSelected,
                        selectedColor: loc.color,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : null,
                        ),
                        onSelected: (_) {
                          ref.read(foodListControllerProvider.notifier).setStorageLocation(loc);
                        },
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // 4. Freshness Status Filter Tabs & Quick Toggles (Favorites & Low-Stock)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        // Status chips
                        ...[
                          (label: 'All', status: null),
                          (label: 'Fresh', status: FoodStatus.fresh),
                          (label: 'Expiring Soon', status: FoodStatus.expiringSoon),
                          (label: 'Expired', status: FoodStatus.expired),
                          (label: 'Rescued', status: FoodStatus.consumed),
                        ].map((tab) {
                          final isSelected = listState.filter.status == tab.status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(tab.label),
                              selected: isSelected,
                              selectedColor: ColorPalette.freshEmerald,
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : null,
                              ),
                              onSelected: (_) {
                                ref.read(foodListControllerProvider.notifier).setStatus(tab.status);
                              },
                            ),
                          );
                        }),
                        const SizedBox(width: 6),

                        // Favorites Filter Chip
                        FilterChip(
                          avatar: Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: listState.filter.isFavorite == true ? Colors.white : ColorPalette.warningAmber,
                          ),
                          label: const Text('Favorites'),
                          selected: listState.filter.isFavorite == true,
                          selectedColor: ColorPalette.warningAmber,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: listState.filter.isFavorite == true ? Colors.white : null,
                          ),
                          onSelected: (val) {
                            ref.read(foodListControllerProvider.notifier).setFavoriteOnly(val ? true : null);
                          },
                        ),
                        const SizedBox(width: 6),

                        // Low-Stock Filter Chip
                        FilterChip(
                          avatar: Icon(
                            Icons.warning_amber_rounded,
                            size: 15,
                            color: listState.filter.isLowStock == true ? Colors.white : ColorPalette.sunsetCoral,
                          ),
                          label: const Text('Low Stock'),
                          selected: listState.filter.isLowStock == true,
                          selectedColor: ColorPalette.sunsetCoral,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: listState.filter.isLowStock == true ? Colors.white : null,
                          ),
                          onSelected: (val) {
                            ref.read(foodListControllerProvider.notifier).setLowStockOnly(val ? true : null);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 5. Pantry Items Count & Reset
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    children: [
                      listState.items.maybeWhen(
                        data: (items) => Text(
                          'Showing ${items.length} item(s)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? ColorPalette.darkTextSecondary
                                : ColorPalette.lightTextSecondary,
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const Spacer(),
                      if (listState.filter.hasActiveFilter)
                        InkWell(
                          onTap: () {
                            ref.read(foodListControllerProvider.notifier).setCategory(null);
                            ref.read(foodListControllerProvider.notifier).setStorageLocation(null);
                            ref.read(foodListControllerProvider.notifier).setStatus(null);
                            ref.read(foodListControllerProvider.notifier).setFavoriteOnly(null);
                            ref.read(foodListControllerProvider.notifier).setLowStockOnly(null);
                            ref.read(foodListControllerProvider.notifier).setSearchQuery('');
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              'Clear All Filters',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: ColorPalette.freshEmerald,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // 6. Items List
              listState.items.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ColorPalette.freshEmerald,
                    ),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorStateView(
                    message: err.toString(),
                    onRetry: () => ref
                        .read(foodListControllerProvider.notifier)
                        .loadItems(),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateView(
                        icon: listState.filter.hasActiveFilter
                            ? Icons.search_off_rounded
                            : Icons.inventory_2_outlined,
                        title: listState.filter.hasActiveFilter
                            ? 'No grocery items match filters'
                            : 'Your grocery pantry is empty!',
                        description: listState.filter.hasActiveFilter
                            ? 'Try selecting a different storage location, category or clearing search terms.'
                            : 'Tap "+ Add" to log grocery items and track expiration dates.',
                        actionLabel: listState.filter.hasActiveFilter
                            ? 'Clear Filters'
                            : 'Load Sample Groceries',
                        onAction: () async {
                          if (listState.filter.hasActiveFilter) {
                            ref.read(foodListControllerProvider.notifier).setCategory(null);
                            ref.read(foodListControllerProvider.notifier).setStorageLocation(null);
                            ref.read(foodListControllerProvider.notifier).setStatus(null);
                            ref.read(foodListControllerProvider.notifier).setFavoriteOnly(null);
                            ref.read(foodListControllerProvider.notifier).setLowStockOnly(null);
                            ref.read(foodListControllerProvider.notifier).setSearchQuery('');
                          } else {
                            await ref.read(foodListControllerProvider.notifier).resetDemoData();
                          }
                        },
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FoodCard(
                              item: item,
                              warningDays: listState.warningDays,
                              onTap: () => context.push(
                                RoutePaths.foodDetailPath(item.id),
                              ),
                              onEdit: () => context.push(
                                RoutePaths.editFoodPath(item.id),
                              ),
                              onDelete: () async {
                                final confirmed = await ConfirmationDialog.show(
                                  context,
                                  title: 'Delete Grocery Item',
                                  message: 'Are you sure you want to delete ${item.name}? This action cannot be undone.',
                                  confirmLabel: 'Delete',
                                  isDestructive: true,
                                  icon: Icons.delete_outline_rounded,
                                );
                                if (confirmed == true) {
                                  await ref
                                      .read(foodListControllerProvider.notifier)
                                      .deleteFood(item.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Deleted ${item.name}'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              onConsume: (qty) async {
                                await ref
                                    .read(foodListControllerProvider.notifier)
                                    .consumeFood(item.id, qty);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Logged $qty ${item.unit.displayName} of ${item.name} as rescued!'),
                                      backgroundColor: ColorPalette.freshEmeraldDark,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGroceryMenu(context, isDark),
        backgroundColor: ColorPalette.freshEmerald,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Add Grocery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  void _showAddGroceryMenu(BuildContext context, bool isDark) {
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
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, color: ColorPalette.freshEmerald, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Add Grocery to Inventory',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorPalette.freshEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: ColorPalette.freshEmerald, size: 22),
                  ),
                  title: const Text('Scan Grocery Barcode', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  subtitle: const Text('Point camera at product SKU for instant lookup', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(RoutePaths.barcodeScanner);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorPalette.warningAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: ColorPalette.warningAmber, size: 22),
                  ),
                  title: const Text('Quick Add (Smart Presets)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  subtitle: const Text('Add milk, rice, bread, or staples in seconds', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).pop();
                    QuickAddDialog.show(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  title: const Text('Manual Entry Form', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  subtitle: const Text('Enter custom dates, prices, and storage locations', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(RoutePaths.addFood);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

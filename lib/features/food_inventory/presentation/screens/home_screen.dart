import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../domain/entities/food_status.dart';
import '../providers/food_list_controller.dart';
import '../providers/food_stats_controller.dart';
import '../widgets/food_card.dart';
import '../widgets/food_search_bar.dart';
import '../widgets/food_sort_sheet.dart';
import '../widgets/pantry_hero_card.dart';
import '../widgets/quick_add_dialog.dart';
import '../widgets/status_metric_grid.dart';
import '../widgets/urgent_expiring_carousel.dart';
import '../widgets/use_it_first_section.dart';

/// Clean & Vibrant Home Screen matching the Groceries design system
class HomeScreen extends ConsumerWidget {
  final VoidCallback? onOpenPantryTab;
  final VoidCallback? onOpenCalendarTab;

  const HomeScreen({
    super.key,
    this.onOpenPantryTab,
    this.onOpenCalendarTab,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning, Chef 👋';
    } else if (hour < 17) {
      return 'Good afternoon, Chef 👋';
    } else {
      return 'Good evening, Chef 👋';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listState = ref.watch(foodListControllerProvider);
    final statsAsync = ref.watch(foodStatsControllerProvider);

    final stats = statsAsync.valueOrNull;
    final urgentAlertCount = (stats?.expiringSoon ?? 0) + (stats?.expiresToday ?? 0) + (stats?.expired ?? 0);

    // Urgent groceries expiring in 0-3 days for "Use It First"
    final urgentItems = listState.items.valueOrNull
            ?.where((i) => !i.isConsumed && i.daysUntilExpiry() <= listState.warningDays)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: isDark ? ColorPalette.darkBg : ColorPalette.lightBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ColorPalette.freshEmerald,
          onRefresh: () async {
            await ref.read(foodListControllerProvider.notifier).loadItems();
            await ref.read(foodStatsControllerProvider.notifier).loadStats();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Top Header: Greeting & Quick Add + Notification Bell with Badge
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: -0.4,
                                color: isDark
                                    ? ColorPalette.darkTextPrimary
                                    : ColorPalette.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Let's keep your pantry fresh",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? ColorPalette.darkTextSecondary
                                    : ColorPalette.lightTextSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Right Actions: Scan Barcode, Quick Add Pill & Notification Bell with Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scan Barcode Button
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? ColorPalette.darkBorder
                                    : ColorPalette.lightBorder,
                                width: 1.0,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 20,
                                color: ColorPalette.freshEmerald,
                              ),
                              tooltip: 'Scan Any Product Barcode',
                              onPressed: () => context.push(RoutePaths.barcodeScanner),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Quick Add (Flash) Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => QuickAddDialog.show(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  gradient: ColorPalette.freshButtonGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorPalette.freshEmerald.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flash_on_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Quick Add',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Notification Bell with Badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? ColorPalette.darkCard
                                      : ColorPalette.lightCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? ColorPalette.darkBorder
                                        : ColorPalette.lightBorder,
                                    width: 1.0,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 22,
                                  ),
                                  tooltip: 'Alerts',
                                  color: isDark
                                      ? ColorPalette.darkTextPrimary
                                      : ColorPalette.lightTextPrimary,
                                  onPressed: () => context.push(RoutePaths.notifications),
                                ),
                              ),
                              if (urgentAlertCount > 0)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE11D48),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '$urgentAlertCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 4)),

              // 2. Search Bar at Top of Home Screen
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FoodSearchBar(
                    initialQuery: listState.filter.searchQuery,
                    currentSort: listState.filter.sortOption,
                    showSortButton: false,
                    hintText: 'Search products, medicines, barcodes...',
                    onScanPressed: () => context.push(RoutePaths.barcodeScanner),
                    onQueryChanged: (query) {
                      ref
                          .read(foodListControllerProvider.notifier)
                          .setSearchQuery(query);
                    },
                  ),
                ),
              ),

              // 3. Hero Pantry Overview Card
              SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (statsData) => PantryHeroCard(
                    stats: statsData,
                    onTap: onOpenPantryTab,
                  ),
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: ColorPalette.freshEmerald,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 4. Quick Status Metric Cards
              SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (statsData) => StatusMetricGrid(
                    stats: statsData,
                    onCardTap: (index) {
                      if (index == 1) {
                        ref.read(foodListControllerProvider.notifier).setStatus(FoodStatus.expiringSoon);
                      } else if (index == 2) {
                        ref.read(foodListControllerProvider.notifier).setStatus(FoodStatus.expiringSoon);
                      } else if (index == 3) {
                        ref.read(foodListControllerProvider.notifier).setStatus(FoodStatus.expired);
                      } else if (index == 4) {
                        ref.read(foodListControllerProvider.notifier).setStatus(FoodStatus.consumed);
                      } else {
                        ref.read(foodListControllerProvider.notifier).setStatus(null);
                      }
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 5. "Use It First" Section (Urgent items with Details + Recipes actions)
              if (urgentItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: UseItFirstSection(urgentItems: urgentItems),
                ),

              if (urgentItems.isNotEmpty) const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 6. "Urgent: Use Today" Carousel
              listState.items.maybeWhen(
                data: (items) {
                  return SliverToBoxAdapter(
                    child: UrgentExpiringCarousel(
                      items: items,
                      warningDays: listState.warningDays,
                      onViewAll: onOpenPantryTab ??
                          () {
                            ref.read(foodListControllerProvider.notifier).setStatus(FoodStatus.expiringSoon);
                          },
                      onItemTap: (item) => context.push(
                        RoutePaths.foodDetailPath(item.id),
                      ),
                      onConsume: (item, qty) async {
                        await ref
                            .read(foodListControllerProvider.notifier)
                            .consumeFood(item.id, qty);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logged ${item.name} as used!'),
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
                orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 7. "All Grocery Items" Section Header with "Sort >" Link
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'All Grocery Items',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 16.5,
                            letterSpacing: -0.3,
                            color: isDark
                                ? ColorPalette.darkTextPrimary
                                : ColorPalette.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      listState.items.maybeWhen(
                        data: (items) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? ColorPalette.darkSurfaceHighlight
                                : ColorPalette.lightSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${items.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? ColorPalette.freshEmerald
                                  : ColorPalette.freshEmeraldDark,
                            ),
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const Spacer(),

                      // Active filter indicator / Reset button
                      if (listState.filter.hasActiveFilter) ...[
                        InkWell(
                          onTap: () {
                            ref.read(foodListControllerProvider.notifier).setCategory(null);
                            ref.read(foodListControllerProvider.notifier).setStatus(null);
                            ref.read(foodListControllerProvider.notifier).setSearchQuery('');
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: ColorPalette.sunsetCoral,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Sort > Action Button
                      InkWell(
                        onTap: () {
                          FoodSortSheet.show(
                            context,
                            currentSort: listState.filter.sortOption,
                            onSortSelected: (sort) {
                              ref.read(foodListControllerProvider.notifier).setSortOption(sort);
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sort',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: Color(0xFF0284C7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // 8. Ingredients List Items
              listState.items.when(
                loading: () => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            height: 76,
                            decoration: BoxDecoration(
                              color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                              ),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: ColorPalette.freshEmerald,
                                  strokeWidth: 2.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: 3,
                    ),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorStateView(
                    message: err.toString(),
                    onRetry: () => ref.read(foodListControllerProvider.notifier).loadItems(),
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
                            ? 'No matching grocery items found'
                            : 'Your grocery pantry is all fresh!',
                        description: listState.filter.hasActiveFilter
                            ? 'Try clearing your filters to view all grocery items in your pantry.'
                            : 'Tap "+ Add" to log grocery items and track expiration dates.',
                        actionLabel: listState.filter.hasActiveFilter
                            ? 'Clear Filters'
                            : 'Load Sample Groceries',
                        onAction: () async {
                          if (listState.filter.hasActiveFilter) {
                            ref.read(foodListControllerProvider.notifier).setCategory(null);
                            ref.read(foodListControllerProvider.notifier).setStatus(null);
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
                                  message: 'Are you sure you want to delete ${item.name}?',
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
    );
  }
}

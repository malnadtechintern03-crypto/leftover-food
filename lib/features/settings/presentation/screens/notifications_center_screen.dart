import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../food_inventory/domain/entities/food_status.dart';
import '../../../food_inventory/presentation/providers/food_list_controller.dart';
import '../../../food_inventory/presentation/widgets/food_card.dart';
import '../providers/settings_controller.dart';

/// Screen listing urgent alerts and expiring leftovers needing attention
class NotificationsCenterScreen extends ConsumerWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final listState = ref.watch(foodListControllerProvider);
    final settings = ref.watch(settingsControllerProvider).valueOrNull;
    final warningDays = settings?.expiryWarningDays ?? 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expiring Alerts',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: listState.items.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ColorPalette.primaryGreen),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allItems) {
          final urgentItems = allItems.where((item) {
            final status = item.getStatus(warningDays: warningDays);
            return status == FoodStatus.expiringSoon || status == FoodStatus.expired;
          }).toList();

          if (urgentItems.isEmpty) {
            return const EmptyStateView(
              icon: Icons.notifications_none_rounded,
              title: 'No urgent items expiring',
              description:
                  'All your tracked leftovers are fresh and well within their shelf life!',
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? ColorPalette.warningAmberDarkBg.withValues(alpha: 0.4)
                      : ColorPalette.warningAmberBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ColorPalette.warningAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: ColorPalette.warningAmber,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have ${urgentItems.length} item(s) that need your attention soon to avoid food waste.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? ColorPalette.darkTextPrimary
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...urgentItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FoodCard(
                    item: item,
                    warningDays: warningDays,
                    onTap: () => context.push(RoutePaths.foodDetailPath(item.id)),
                    onConsume: (qty) async {
                      await ref
                          .read(foodListControllerProvider.notifier)
                          .consumeFood(item.id, qty);
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

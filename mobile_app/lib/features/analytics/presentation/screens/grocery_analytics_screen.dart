import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../budget/presentation/providers/budget_controller.dart';
import '../../../food_inventory/presentation/providers/food_stats_controller.dart';
import '../../../waste_tracking/presentation/providers/waste_controller.dart';

/// Grocery Analytics & Waste Tracking Dashboard with INR Budget calculations
class GroceryAnalyticsScreen extends ConsumerWidget {
  const GroceryAnalyticsScreen({super.key});

  void _showEditBudgetDialog(BuildContext context, WidgetRef ref, double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Grocery Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Monthly Limit (₹)',
            prefixIcon: Center(
              widthFactor: 1,
              child: Text('₹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text.trim());
              if (newLimit != null && newLimit > 0) {
                ref.read(budgetControllerProvider.notifier).setMonthlyLimit(newLimit);
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorPalette.freshEmerald),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statsState = ref.watch(foodStatsControllerProvider);
    final budgetState = ref.watch(budgetControllerProvider);
    final wasteState = ref.watch(wasteControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grocery & Waste Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(foodStatsControllerProvider.notifier).loadStats();
              ref.read(budgetControllerProvider.notifier).loadBudget();
              ref.read(wasteControllerProvider.notifier).loadData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Budget Tracker Card
            _buildBudgetCard(context, ref, budgetState, isDark),

            const SizedBox(height: 16),

            // 2. Rescued vs Expired / Wasted Metrics
            Text(
              'Pantry Performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            statsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading stats: $e'),
              data: (stats) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Used / Rescued',
                        value: '${stats.totalConsumed}',
                        subtitle: 'Safely consumed',
                        icon: Icons.check_circle_rounded,
                        color: ColorPalette.freshEmerald,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Active Pantry',
                        value: '${stats.totalActive}',
                        subtitle: '${stats.fresh} fresh items',
                        icon: Icons.kitchen_rounded,
                        color: const Color(0xFF0284C7),
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // 3. Waste Tracking Breakdown
            Text(
              'Waste & Losses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            wasteState.stats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading waste stats: $e'),
              data: (wasteStats) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Money Lost',
                            value: '₹${wasteStats.totalWastedCost.toStringAsFixed(0)}',
                            subtitle: '${wasteStats.totalWasteRecords} discarded items',
                            icon: Icons.money_off_rounded,
                            color: ColorPalette.expiredRed,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Most Discarded',
                            value: wasteStats.mostWastedItem ?? 'None 🎉',
                            subtitle: 'Based on waste logs',
                            icon: Icons.trending_down_rounded,
                            color: ColorPalette.sunsetCoral,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Waste by Reason Breakdown Card
                    if (wasteStats.wasteByReason.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Waste by Reason',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            ...wasteStats.wasteByReason.entries.map((e) {
                              final pct = wasteStats.totalWasteRecords > 0
                                  ? (e.value / wasteStats.totalWasteRecords)
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(e.key, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                        Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 6,
                                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                        color: ColorPalette.sunsetCoral,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Clear Waste History Button
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Reset Waste History'),
                style: TextButton.styleFrom(foregroundColor: ColorPalette.expiredRed),
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.show(
                    context,
                    title: 'Reset Waste Records',
                    message: 'Are you sure you want to clear all logged waste records?',
                    confirmLabel: 'Reset',
                  );
                  if (confirmed == true) {
                    await ref.read(wasteControllerProvider.notifier).clearAll();
                  }
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    WidgetRef ref,
    BudgetState budget,
    bool isDark,
  ) {
    final progress = budget.spentPercentage.clamp(0.0, 1.0);
    final isWarning = progress >= 0.75 && !budget.isOverBudget;
    final isDanger = budget.isOverBudget;

    final progressColor = isDanger
        ? ColorPalette.expiredRed
        : isWarning
            ? ColorPalette.warningAmber
            : ColorPalette.freshEmerald;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: progressColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded, color: progressColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Monthly Grocery Budget',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                tooltip: 'Edit monthly limit',
                onPressed: () => _showEditBudgetDialog(context, ref, budget.monthlyLimit),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Spend & Limit Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent this Month',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${budget.totalSpentThisMonth.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isDanger ? 'Over Budget by' : 'Remaining',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDanger ? ColorPalette.expiredRed : (isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${isDanger ? (budget.totalSpentThisMonth - budget.monthlyLimit).toStringAsFixed(0) : budget.remainingBudget.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              color: progressColor,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Target Limit: ₹${budget.monthlyLimit.toStringAsFixed(0)} / month',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

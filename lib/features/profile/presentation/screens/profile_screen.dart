import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/utils/data_backup_helper.dart';
import '../../../../core/utils/data_export_helper.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../food_inventory/presentation/providers/food_list_controller.dart';
import '../../../food_inventory/presentation/providers/food_stats_controller.dart';
import '../../../settings/presentation/widgets/food_tips_sheet.dart';
import '../../../shopping_list/presentation/providers/shopping_list_controller.dart';

/// Kitchen Profile Screen with User Info, Pantry Statistics, Preferences, Data Management, Backup & Restore
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    final foodState = ref.read(foodListControllerProvider);
    final shoppingState = ref.read(shoppingListControllerProvider);

    showModalBottomSheet(
      context: context,
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Export Grocery Data (CSV)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.inventory_2_rounded, color: ColorPalette.freshEmerald),
                  title: const Text('Export Active Groceries CSV', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('All pantry inventory records and expiry dates', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(context).pop();
                    final items = foodState.items.valueOrNull ?? [];
                    final csv = DataExportHelper.exportGroceriesToCsv(items);
                    DataExportHelper.copyCsvToClipboard(context, csv, 'Groceries Inventory');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF0284C7)),
                  title: const Text('Export Shopping List CSV', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Shopping items with priorities and status', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(context).pop();
                    final items = shoppingState.items.valueOrNull ?? [];
                    final csv = DataExportHelper.exportShoppingListToCsv(items);
                    DataExportHelper.copyCsvToClipboard(context, csv, 'Shopping List');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBackupRestoreDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Local Backup & Restore (JSON)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.cloud_download_rounded, color: ColorPalette.freshEmerald),
                  title: const Text('Create Full JSON Backup', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Copies full JSON backup data to clipboard', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final jsonString = await DataBackupHelper.generateBackupJson();
                    Clipboard.setData(ClipboardData(text: jsonString));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Full JSON backup copied to clipboard! Save it in a safe note.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_rounded, color: ColorPalette.sunsetCoral),
                  title: const Text('Restore from JSON Backup', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Paste backup JSON to overwrite & restore database', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showRestoreInputDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRestoreInputDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Backup JSON'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste backup JSON here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final jsonText = controller.text.trim();
              if (jsonText.isEmpty) return;

              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Confirm Restore',
                message: 'Restoring will replace all existing grocery and shopping data with the backup. Continue?',
                confirmLabel: 'Restore',
                isDestructive: true,
              );

              if (confirmed == true) {
                try {
                  await DataBackupHelper.restoreFromJson(jsonText);
                  ref.read(foodListControllerProvider.notifier).loadItems();
                  ref.read(foodStatsControllerProvider.notifier).loadStats();
                  ref.read(shoppingListControllerProvider.notifier).loadItems();

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Database restored successfully from backup!'),
                        backgroundColor: ColorPalette.freshEmeraldDark,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to restore: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorPalette.freshEmerald),
            child: const Text('Restore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statsAsync = ref.watch(foodStatsControllerProvider);
    final stats = statsAsync.valueOrNull;

    final totalActive = stats?.totalActive ?? 0;
    final rescuedCount = stats?.totalConsumed ?? 0;
    final expiredCount = stats?.expired ?? 0;
    final totalManaged = totalActive + rescuedCount + expiredCount;
    final preventionRate = totalManaged > 0
        ? (((totalManaged - expiredCount) / totalManaged) * 100).round()
        : 100;
    final estimatedSavings = (rescuedCount * 85.0).toStringAsFixed(0);
    final co2Avoided = (rescuedCount * 1.8).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: isDark ? ColorPalette.darkBg : ColorPalette.lightBg,
      appBar: AppBar(
        title: Text(
          'Chef Profile & Tools',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          // 1. Chef Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    gradient: ColorPalette.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.soup_kitchen_rounded, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Chef Kitchen',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, size: 16, color: ColorPalette.freshEmerald),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pantry Master • Level 5',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: ColorPalette.freshEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Zero-Waste Hero 🌿',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: ColorPalette.freshEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Section Title: Pantry Statistics
          Text(
            'Pantry Statistics',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // 2. Statistics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Active Groceries',
                  value: '$totalActive items',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF0284C7),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Rescued / Used',
                  value: '$rescuedCount items',
                  icon: Icons.eco_rounded,
                  color: ColorPalette.freshEmerald,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Waste Prevention',
                  value: '$preventionRate%',
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Zero-Waste Streak',
                  value: '14 Days 🔥',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFEA580C),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Estimated Savings',
                  value: '₹$estimatedSavings',
                  icon: Icons.savings_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'CO2 Avoided',
                  value: '$co2Avoided kg',
                  icon: Icons.cloud_done_rounded,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Section Title: Smart Modules & Tools
          Text(
            'Smart Modules & Tools',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),

          _buildListTile(
            context,
            icon: Icons.checklist_rounded,
            title: 'Smart Shopping List',
            subtitle: 'Auto low-stock suggestions & pantry conversion',
            iconColor: ColorPalette.freshEmerald,
            isDark: isDark,
            onTap: () => context.push(RoutePaths.shoppingList),
          ),
          const SizedBox(height: 8),

          _buildListTile(
            context,
            icon: Icons.analytics_rounded,
            title: 'Grocery & Waste Analytics',
            subtitle: 'Monthly budget in ₹, spend tracking & waste reasons',
            iconColor: const Color(0xFF8B5CF6),
            isDark: isDark,
            onTap: () => context.push(RoutePaths.analytics),
          ),
          const SizedBox(height: 8),

          _buildListTile(
            context,
            icon: Icons.file_download_rounded,
            title: 'Export Data (CSV)',
            subtitle: 'Export grocery pantry & shopping list to CSV',
            iconColor: const Color(0xFF0284C7),
            isDark: isDark,
            onTap: () => _showExportDialog(context, ref),
          ),
          const SizedBox(height: 8),

          _buildListTile(
            context,
            icon: Icons.backup_rounded,
            title: 'Local Backup & Restore (JSON)',
            subtitle: 'Export JSON backup or restore SQLite database',
            iconColor: const Color(0xFFD97706),
            isDark: isDark,
            onTap: () => _showBackupRestoreDialog(context, ref),
          ),

          const SizedBox(height: 22),

          // Section Title: Preferences & Notifications
          Text(
            'Preferences & Notifications',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),

          _buildListTile(
            context,
            icon: Icons.lightbulb_outline_rounded,
            title: 'Storage & Freshness Tips',
            subtitle: 'Best practices for storing pantry staples & spices',
            isDark: isDark,
            onTap: () => FoodTipsSheet.show(context),
          ),
          const SizedBox(height: 8),

          _buildListTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Notification Settings',
            subtitle: 'Daily expiry alerts and reminder times',
            isDark: isDark,
            onTap: () => context.push(RoutePaths.notifications),
          ),
          const SizedBox(height: 8),

          _buildListTile(
            context,
            icon: Icons.tune_rounded,
            title: 'App Preferences & Theme',
            subtitle: 'Theme modes, warning thresholds & units',
            isDark: isDark,
            onTap: () => context.push(RoutePaths.settings),
          ),

          const SizedBox(height: 22),

          // Section Title: Manage Pantry Data
          Text(
            'Manage Pantry Data',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),

          _buildListTile(
            context,
            icon: Icons.cleaning_services_rounded,
            title: 'Clear Rescued Groceries',
            subtitle: 'Remove all used/consumed items from history',
            isDark: isDark,
            iconColor: ColorPalette.freshEmerald,
            onTap: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Clear Rescued Groceries',
                message: 'This will remove all logged consumed items from your pantry history. Active grocery items will not be affected.',
                confirmLabel: 'Clear History',
                icon: Icons.cleaning_services_rounded,
              );
              if (confirmed == true) {
                await ref.read(foodListControllerProvider.notifier).clearConsumedItems();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Cleared rescued groceries history'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 8),

          _buildListTile(
            context,
            icon: Icons.restore_rounded,
            title: 'Reset Demo Groceries',
            subtitle: 'Reload realistic sample grocery items into pantry',
            isDark: isDark,
            iconColor: const Color(0xFF0284C7),
            onTap: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Reset Demo Groceries',
                message: 'This will reset your pantry with fresh demo grocery items across all 8 grocery categories.',
                confirmLabel: 'Reset Demo',
                icon: Icons.restore_rounded,
              );
              if (confirmed == true) {
                await ref.read(foodListControllerProvider.notifier).resetDemoData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Reset demo grocery items successfully!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 8),

          _buildListTile(
            context,
            icon: Icons.delete_forever_rounded,
            title: 'Purge All Pantry Data',
            subtitle: 'Permanently delete all grocery items and records',
            isDark: isDark,
            iconColor: ColorPalette.expiredRed,
            onTap: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Purge All Pantry Data',
                message: 'Are you sure you want to delete all grocery items? This action is irreversible.',
                confirmLabel: 'Purge All',
                isDestructive: true,
                icon: Icons.delete_forever_rounded,
              );
              if (confirmed == true) {
                await ref.read(foodListControllerProvider.notifier).clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All pantry data has been deleted.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
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
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ??
        (isDark ? ColorPalette.freshEmerald : ColorPalette.freshEmeraldDark);

    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: effectiveIconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: effectiveIconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: isDark ? ColorPalette.darkTextTertiary : ColorPalette.lightTextTertiary,
        ),
      ),
    );
  }
}

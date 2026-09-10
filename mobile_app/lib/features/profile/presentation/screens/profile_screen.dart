import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/utils/app_review_helper.dart';
import '../../../../core/utils/data_backup_helper.dart';
import '../../../../core/utils/data_export_helper.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../food_inventory/presentation/providers/food_list_controller.dart';
import '../../../food_inventory/presentation/providers/food_stats_controller.dart';
import '../../../settings/presentation/widgets/food_tips_sheet.dart';
import '../../../shopping_list/presentation/providers/shopping_list_controller.dart';

/// Kitchen Profile Screen with User Info, Pantry Statistics, Preferences, Data Management, Backup & Restore
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, User? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: user?.name ?? 'Guest Chef');
    final emailController = TextEditingController(text: user?.email ?? 'guest@homepantry.local');
    final isGuest = user?.isGuest ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            final currentName = nameController.text.trim();
            final parts = currentName.split(RegExp(r'\s+'));
            String previewInitials = 'CK';
            if (parts.isNotEmpty && parts[0].isNotEmpty) {
              if (parts.length == 1) {
                previewInitials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
              } else {
                final first = parts[0][0];
                final second = parts[1].isNotEmpty ? parts[1][0] : '';
                previewInitials = '$first$second'.toUpperCase();
              }
            }

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
              decoration: BoxDecoration(
                color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Drag Handle
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

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ColorPalette.freshEmerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: ColorPalette.freshEmerald,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Chef Profile',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'Personalize your pantry chef identity',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(bottomSheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Live Interactive Avatar Preview
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: ColorPalette.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ColorPalette.freshEmerald.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                previewInitials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isGuest ? ColorPalette.warningAmber : ColorPalette.freshEmerald).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isGuest ? 'Guest Chef 👤' : 'Verified Chef 🌿',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isGuest ? ColorPalette.warningAmber : ColorPalette.freshEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Chef Name Field
                    Text(
                      'Chef Display Name *',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. Chef Alex, Gourmet Kitchen',
                        prefixIcon: const Icon(Icons.person_rounded, color: ColorPalette.freshEmerald, size: 20),
                        filled: true,
                        fillColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Email Field
                    Text(
                      'Contact Email *',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'e.g. chef@example.com',
                        prefixIcon: const Icon(Icons.email_outlined, color: ColorPalette.freshEmerald, size: 20),
                        filled: true,
                        fillColor: isDark ? ColorPalette.darkSurfaceHighlight : ColorPalette.lightSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Guest Mode Notice
                    if (isGuest) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorPalette.warningAmber.withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ColorPalette.warningAmber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: ColorPalette.warningAmber, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Offline Guest Mode Active',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: ColorPalette.warningAmber,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Profile edits are saved safely on this phone. Want cross-device cloud sync?',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(bottomSheetContext).pop();
                                      context.push(RoutePaths.login);
                                    },
                                    child: const Text(
                                      'Sign In or Create Cloud Account →',
                                      style: TextStyle(
                                        fontSize: 11.5,
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
                    ],

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(bottomSheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final newName = nameController.text.trim();
                              final newEmail = emailController.text.trim();

                              if (newName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a chef display name')),
                                );
                                return;
                              }

                              final success = await ref
                                  .read(authControllerProvider.notifier)
                                  .updateProfile(name: newName, email: newEmail);

                              if (bottomSheetContext.mounted) {
                                Navigator.of(bottomSheetContext).pop();
                              }

                              if (context.mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Chef profile updated to "$newName"! 🎉'),
                                    backgroundColor: ColorPalette.freshEmeraldDark,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            label: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPalette.freshEmerald,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Sign Out?',
      message: 'Are you sure you want to sign out of your account? Your local pantry records will remain safely saved.',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go(RoutePaths.login);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    final isGuest = user?.isGuest ?? false;
    final userName = user?.displayName ?? 'Chef Kitchen';
    final userEmail = user?.email ?? '';
    final userInitials = user?.initials ?? 'CK';

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
          // 1. Chef Profile Card with Edit Action
          Material(
            color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                width: 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showEditProfileSheet(context, ref, user),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        gradient: ColorPalette.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isGuest
                            ? const Icon(Icons.person_outline_rounded, color: Colors.white, size: 30)
                            : Text(
                                userInitials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isGuest ? Icons.shield_outlined : Icons.verified_rounded,
                                size: 16,
                                color: isGuest ? ColorPalette.warningAmber : ColorPalette.freshEmerald,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            userEmail.isNotEmpty ? userEmail : (isGuest ? 'Offline Guest Mode' : 'Pantry Master • Level 5'),
                            overflow: TextOverflow.ellipsis,
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
                              color: (isGuest ? ColorPalette.warningAmber : ColorPalette.freshEmerald).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isGuest ? 'Guest Chef 👤' : 'Verified Chef 🌿',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isGuest ? ColorPalette.warningAmber : ColorPalette.freshEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit Profile Icon Button
                    Tooltip(
                      message: 'Edit Chef Profile',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorPalette.freshEmerald.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: ColorPalette.freshEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
            icon: Icons.edit_note_rounded,
            title: 'Edit Chef Profile',
            subtitle: 'Change chef display name and contact email',
            iconColor: ColorPalette.freshEmerald,
            isDark: isDark,
            onTap: () => _showEditProfileSheet(context, ref, user),
          ),
          const SizedBox(height: 8),

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
          const SizedBox(height: 8),

          _buildListTile(
            context,
            icon: Icons.star_rate_rounded,
            title: 'Rate Home Pantry',
            subtitle: 'Share feedback or rate us on Google Play',
            iconColor: const Color(0xFFF59E0B),
            isDark: isDark,
            onTap: () => AppReviewHelper.openRateApp(context),
          ),
          const SizedBox(height: 8),

          _buildListTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our strict offline data privacy policy',
            iconColor: const Color(0xFF0284C7),
            isDark: isDark,
            onTap: () => AppReviewHelper.openPrivacyPolicy(context),
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

          const SizedBox(height: 22),

          // 8. Account & Security Section
          Text(
            'Account & Security',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),

          if (isGuest) ...[
            _buildListTile(
              context,
              icon: Icons.login_rounded,
              iconColor: ColorPalette.freshEmerald,
              title: 'Sign In / Register',
              subtitle: 'Link your pantry items to a cloud account',
              isDark: isDark,
              onTap: () => context.go(RoutePaths.login),
            ),
            const SizedBox(height: 10),
            _buildListTile(
              context,
              icon: Icons.logout_rounded,
              iconColor: Colors.red.shade600,
              title: 'Exit Guest Session',
              subtitle: 'Return to login screen',
              isDark: isDark,
              onTap: () => _handleLogout(context, ref),
            ),
          ] else ...[
            _buildListTile(
              context,
              icon: Icons.logout_rounded,
              iconColor: Colors.red.shade600,
              title: 'Log Out',
              subtitle: userEmail.isNotEmpty
                  ? 'Signed in as $userEmail'
                  : 'Sign out and return to the login screen',
              isDark: isDark,
              onTap: () => _handleLogout(context, ref),
            ),
          ],

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

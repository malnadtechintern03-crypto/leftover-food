import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/admin_sync_service.dart';
import '../../../../core/services/product_sync_service.dart';
import '../providers/settings_controller.dart';
import '../widgets/food_tips_sheet.dart';

/// Settings screen for managing application preferences and configurations
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading settings: $error')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Appearance Section
              _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Mode',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildThemeOption(
                          context,
                          ref: ref,
                          label: 'System',
                          icon: Icons.brightness_auto_rounded,
                          isSelected: settings.themeMode == ThemeMode.system,
                          mode: ThemeMode.system,
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          ref: ref,
                          label: 'Light',
                          icon: Icons.light_mode_rounded,
                          isSelected: settings.themeMode == ThemeMode.light,
                          mode: ThemeMode.light,
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          ref: ref,
                          label: 'Dark',
                          icon: Icons.dark_mode_rounded,
                          isSelected: settings.themeMode == ThemeMode.dark,
                          mode: ThemeMode.dark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Expiry & Notifications Section
              _buildSectionHeader(
                context,
                'Expiry & Notifications',
                Icons.notifications_active_outlined,
              ),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: Column(
                  children: [
                    // Expiration Alerts Dashboard Shortcut
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorPalette.sunsetCoral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: ColorPalette.sunsetCoral,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'View Expiration Alerts',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: const Text('Manage expired & expiring product alerts'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => context.push(RoutePaths.expirationAlerts),
                    ),
                    const Divider(),

                    // Daily Expiry Reminders
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Product Expiration Reminders',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Enable scheduled alerts before products expire',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorPalette.darkTextSecondary
                              : ColorPalette.lightTextSecondary,
                        ),
                      ),
                      activeThumbColor: ColorPalette.primaryGreen,
                      value: settings.notificationsEnabled,
                      onChanged: (val) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .updateNotificationsEnabled(val);
                      },
                    ),
                    const Divider(),

                    // Daily Summary Alert
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Daily Expiration Summary',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Receive a daily briefing on products expiring today or this week',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorPalette.darkTextSecondary
                              : ColorPalette.lightTextSecondary,
                        ),
                      ),
                      activeThumbColor: ColorPalette.primaryGreen,
                      value: settings.dailySummaryEnabled,
                      onChanged: (val) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .updateDailySummaryEnabled(val);
                      },
                    ),
                    const Divider(),

                    // Sound Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Notification Sound',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Play audio chime when alerts are triggered',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorPalette.darkTextSecondary
                              : ColorPalette.lightTextSecondary,
                        ),
                      ),
                      activeThumbColor: ColorPalette.primaryGreen,
                      value: settings.soundEnabled,
                      onChanged: (val) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .updateSoundEnabled(val);
                      },
                    ),
                    const Divider(),

                    // Vibration Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Vibration',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Vibrate device for expiration reminder notifications',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorPalette.darkTextSecondary
                              : ColorPalette.lightTextSecondary,
                        ),
                      ),
                      activeThumbColor: ColorPalette.primaryGreen,
                      value: settings.vibrationEnabled,
                      onChanged: (val) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .updateVibrationEnabled(val);
                      },
                    ),
                    const Divider(),

                    // Reminder Time
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Daily Reminder Time',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        TimeOfDay(
                          hour: settings.reminderHour,
                          minute: settings.reminderMinute,
                        ).format(context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ColorPalette.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time_rounded, size: 20),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: settings.reminderHour,
                            minute: settings.reminderMinute,
                          ),
                        );
                        if (picked != null) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .updateReminderTime(picked);
                        }
                      },
                    ),
                    const Divider(),

                    // Default Reminder Period selection chips
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Default Reminder Period',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${settings.defaultReminderDays} days before',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: ColorPalette.warningAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [1, 3, 7, 14, 30].map((days) {
                              final isSelected =
                                  settings.defaultReminderDays == days;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: ChoiceChip(
                                    label: Text('${days}d'),
                                    selected: isSelected,
                                    selectedColor: ColorPalette.primaryGreen,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : null,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                    onSelected: (_) {
                                      ref
                                          .read(settingsControllerProvider
                                              .notifier)
                                          .updateDefaultReminderDays(days);
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Admin Backend & Connectivity Section
              _buildSectionHeader(
                context,
                'Admin Backend & Sync',
                Icons.hub_outlined,
              ),
              const SizedBox(height: 12),
              const _AdminConnectivityCard(),

              const SizedBox(height: 24),

              // Educational & Tips
              _buildSectionHeader(
                context,
                'Resources & Guides',
                Icons.lightbulb_outline_rounded,
              ),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryGreenLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tips_and_updates_rounded,
                      color: ColorPalette.primaryGreenDark,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Waste Prevention Guide',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Tips on storage, freezing & portioning'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => FoodTipsSheet.show(context),
                ),
              ),

              const SizedBox(height: 24),

              // App Info
              _buildSectionHeader(context, 'About', Icons.info_outline_rounded),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? ColorPalette.darkBorder
                                : ColorPalette.lightBorder,
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        AppConstants.appName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: const Text(AppConstants.appTagline),
                      trailing: Text(
                        'v${AppConstants.appVersion}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorPalette.darkTextSecondary
                              : ColorPalette.lightTextSecondary,
                        ),
                      ),
                    ),
                    const Divider(),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Offline-First Architecture'),
                      subtitle: Text('All data is saved locally on your device'),
                      leading: Icon(
                        Icons.cloud_off_rounded,
                        color: ColorPalette.primaryGreen,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: ColorPalette.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: child,
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required bool isSelected,
    required ThemeMode mode,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(settingsControllerProvider.notifier).updateThemeMode(mode);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? ColorPalette.freshGreenDarkBg : ColorPalette.primaryGreenLight)
                : (isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? ColorPalette.primaryGreen
                  : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (isDark ? ColorPalette.primaryGreenLight : ColorPalette.primaryGreenDark)
                    : (isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? (isDark ? Colors.white : ColorPalette.primaryGreenDark)
                      : (isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that displays the connectivity status to the PHP/MySQL Admin Backend
/// and provides manual sync and endpoint configuration capabilities.
class _AdminConnectivityCard extends StatefulWidget {
  const _AdminConnectivityCard();

  @override
  State<_AdminConnectivityCard> createState() => _AdminConnectivityCardState();
}

class _AdminConnectivityCardState extends State<_AdminConnectivityCard> {
  bool _isChecking = false;
  bool _isSyncing = false;
  bool? _isConnected;
  int? _latencyMs;
  String? _statusMessage;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    // Do not run background network calls during automated widget tests
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _checkConnectivity();
    }
  }

  Future<void> _checkConnectivity([String? overrideUrl]) async {
    if (!mounted) return;
    setState(() {
      _isChecking = true;
    });

    try {
      final result = await AdminSyncService.pingServer(overrideUrl);
      if (!mounted) return;
      setState(() {
        _isConnected = result['connected'] as bool? ?? false;
        _currentUrl = result['url'] as String?;
        _latencyMs = result['latencyMs'] as int?;
        _statusMessage = result['message'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _statusMessage = 'Ping failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _syncQueue() async {
    if (!mounted) return;
    setState(() {
      _isSyncing = true;
    });

    try {
      final syncResult = await ProductSyncService.instance.syncPendingQueue();
      if (!mounted) return;

      final message = syncResult.syncedCount > 0
          ? 'Successfully synced ${syncResult.syncedCount} item(s) to Admin Backend!'
          : (syncResult.failedCount > 0
              ? 'Sync encountered ${syncResult.failedCount} error(s). Backend may be offline.'
              : 'Sync completed. All records are up to date.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: syncResult.failedCount > 0
              ? Colors.deepOrange
              : ColorPalette.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // Also refresh connectivity status after syncing
      await _checkConnectivity();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _showConfigureUrlDialog() {
    final controller = TextEditingController(text: _currentUrl ?? 'http://localhost:8000');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Admin API URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the host URL for the PHP Admin backend REST API. Examples:\n'
              '• http://localhost:8000 (Desktop / Local)\n'
              '• http://10.0.2.2:8000 (Android Emulator)\n'
              '• http://192.168.x.x:8000 (Physical Phone on Wi-Fi)',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://localhost:8000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AdminSyncService.setCustomBaseUrl(null);
              AdminSyncService.clearResolvedBaseUrl();
              Navigator.of(ctx).pop();
              _checkConnectivity();
            },
            child: const Text('Reset Default'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColorPalette.primaryGreen),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                AdminSyncService.setCustomBaseUrl(newUrl);
                ProductSyncService.instance.setBaseUrl('$newUrl/api');
              }
              Navigator.of(ctx).pop();
              _checkConnectivity(newUrl.isNotEmpty ? newUrl : null);
            },
            child: const Text('Save & Test'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorPalette.freshGreenDarkBg
                        : ColorPalette.primaryGreenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cloud_sync_rounded,
                    color: ColorPalette.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin REST API',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentUrl ?? 'Auto-detecting (localhost:8000 / 10.0.2.2)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorPalette.darkTextSecondary
                              : ColorPalette.lightTextSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  tooltip: 'Configure URL',
                  onPressed: _showConfigureUrlDialog,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Connectivity status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isConnected == true
                    ? (isDark
                        ? Colors.green.withAlpha(40)
                        : Colors.green.withAlpha(30))
                    : (_isConnected == false
                        ? (isDark
                            ? Colors.amber.withAlpha(40)
                            : Colors.amber.withAlpha(30))
                        : (isDark
                            ? Colors.white10
                            : Colors.black.withAlpha(10))),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isConnected == true
                      ? Colors.green.withAlpha(100)
                      : (_isConnected == false
                          ? Colors.amber.withAlpha(100)
                          : Colors.transparent),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected == true
                        ? Icons.check_circle_rounded
                        : (_isConnected == false
                            ? Icons.wifi_off_rounded
                            : Icons.help_outline_rounded),
                    size: 16,
                    color: _isConnected == true
                        ? Colors.green
                        : (_isConnected == false ? Colors.amber.shade800 : Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isChecking
                          ? 'Checking Admin server...'
                          : (_statusMessage ??
                              (_isConnected == true
                                  ? 'Connected (${_latencyMs ?? 0}ms)'
                                  : 'Offline / Offline Mode Active')),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isConnected == true
                            ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                            : (_isConnected == false
                                ? (isDark ? Colors.amberAccent : Colors.amber.shade900)
                                : null),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isChecking ? null : () => _checkConnectivity(),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Test Ping'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSyncing ? null : _syncQueue,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Sync Queue'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorPalette.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


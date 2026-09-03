import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/constants/app_constants.dart';
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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Daily Expiry Reminders',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Get notified about food expiring soon',
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Reminder Time',
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Expiry Warning Window',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${settings.expiryWarningDays} ${settings.expiryWarningDays == 1 ? "day" : "days"} before',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: ColorPalette.warningAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [1, 2, 3, 5].map((days) {
                              final isSelected =
                                  settings.expiryWarningDays == days;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text('$days d'),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      ref
                                          .read(settingsControllerProvider
                                              .notifier)
                                          .updateExpiryWarningDays(days);
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

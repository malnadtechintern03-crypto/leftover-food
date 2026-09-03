import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/app_initializer.dart';
import '../models/app_settings_model.dart';

/// Data source interface for settings storage
abstract class SettingsLocalDataSource {
  Future<AppSettingsModel> getSettings();
  Future<void> saveSettings(AppSettingsModel settings);
  Future<bool> hasSeededInitialData();
  Future<void> setSeededInitialData(bool seeded);
}

/// Robust SharedPreferences implementation of SettingsLocalDataSource with dynamic resolution
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences? _prefs;
  AppSettingsModel? _inMemorySettings;
  bool _inMemoryHasSeeded = false;

  SettingsLocalDataSourceImpl(this._prefs);

  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    if (AppInitializer.instance.sharedPreferences != null) {
      return AppInitializer.instance.sharedPreferences;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      AppInitializer.instance.setSharedPreferences(prefs);
      return prefs;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppSettingsModel> getSettings() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) {
        return _inMemorySettings ??
            const AppSettingsModel(
              themeMode: ThemeMode.system,
              expiryWarningDays: AppConstants.defaultExpiryWarningDays,
              notificationsEnabled: true,
              reminderHour: AppConstants.defaultReminderHour,
              reminderMinute: AppConstants.defaultReminderMinute,
            );
      }

      final themeStr = prefs.getString(AppConstants.keyThemeMode) ?? 'system';
      final warningDays = prefs.getInt(AppConstants.keyExpiryWarningDays) ??
          AppConstants.defaultExpiryWarningDays;
      final notifEnabled =
          prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
      final reminderHour = prefs.getInt(AppConstants.keyReminderHour) ??
          AppConstants.defaultReminderHour;
      final reminderMinute = prefs.getInt(AppConstants.keyReminderMinute) ??
          AppConstants.defaultReminderMinute;

      ThemeMode themeMode = ThemeMode.system;
      if (themeStr == 'dark') themeMode = ThemeMode.dark;
      if (themeStr == 'light') themeMode = ThemeMode.light;

      final loaded = AppSettingsModel(
        themeMode: themeMode,
        expiryWarningDays: warningDays,
        notificationsEnabled: notifEnabled,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
      );
      _inMemorySettings = loaded;
      return loaded;
    } catch (e) {
      throw DatabaseException('Failed to load settings from storage: $e');
    }
  }

  @override
  Future<void> saveSettings(AppSettingsModel settings) async {
    try {
      _inMemorySettings = settings;
      final prefs = await _getPrefs();
      if (prefs != null) {
        await prefs.setString(AppConstants.keyThemeMode, settings.themeMode.name);
        await prefs.setInt(
            AppConstants.keyExpiryWarningDays, settings.expiryWarningDays);
        await prefs.setBool(
            AppConstants.keyNotificationsEnabled, settings.notificationsEnabled);
        await prefs.setInt(AppConstants.keyReminderHour, settings.reminderHour);
        await prefs.setInt(
            AppConstants.keyReminderMinute, settings.reminderMinute);
      }
    } catch (e) {
      throw DatabaseException('Failed to save settings to storage: $e');
    }
  }

  @override
  Future<bool> hasSeededInitialData() async {
    final prefs = await _getPrefs();
    if (prefs == null) return _inMemoryHasSeeded;
    return prefs.getBool(AppConstants.keyHasSeededInitialData) ?? false;
  }

  @override
  Future<void> setSeededInitialData(bool seeded) async {
    _inMemoryHasSeeded = seeded;
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setBool(AppConstants.keyHasSeededInitialData, seeded);
    }
  }
}

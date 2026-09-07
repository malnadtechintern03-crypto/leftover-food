import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/core/constants/app_constants.dart';
import 'package:foodsave/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:foodsave/features/settings/data/models/app_settings_model.dart';
import 'package:foodsave/features/settings/presentation/providers/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeMode Persistence & App Restart Tests', () {
    test('Saving dark theme mode persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final dataSource = SettingsLocalDataSourceImpl(prefs);
      await dataSource.saveSettings(
        const AppSettingsModel(themeMode: ThemeMode.dark),
      );

      expect(prefs.getString(AppConstants.keyThemeMode), 'dark');

      // Simulate app restart by creating a new data source instance reading from disk
      final newDataSource = SettingsLocalDataSourceImpl(prefs);
      final restoredSettings = await newDataSource.getSettings();

      expect(restoredSettings.themeMode, ThemeMode.dark);
    });

    test('Saving light theme mode persists and restores properly', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyThemeMode: 'dark',
      });
      final prefs = await SharedPreferences.getInstance();

      final dataSource = SettingsLocalDataSourceImpl(prefs);
      await dataSource.saveSettings(
        const AppSettingsModel(themeMode: ThemeMode.light),
      );

      expect(prefs.getString(AppConstants.keyThemeMode), 'light');

      // Simulate app restart
      final newDataSource = SettingsLocalDataSourceImpl(prefs);
      final restoredSettings = await newDataSource.getSettings();

      expect(restoredSettings.themeMode, ThemeMode.light);
    });

    test('SettingsController updates themeMode and restores across container restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Initialize controller
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await container.read(settingsControllerProvider.notifier).updateThemeMode(ThemeMode.dark);
      expect(prefs.getString(AppConstants.keyThemeMode), 'dark');
      expect(container.read(settingsControllerProvider).valueOrNull?.themeMode, ThemeMode.dark);

      // Simulate complete app termination and restart with a brand new ProviderContainer
      final newContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await newContainer.read(settingsControllerProvider.notifier).loadSettings();
      expect(newContainer.read(settingsControllerProvider).valueOrNull?.themeMode, ThemeMode.dark);
    });
  });
}

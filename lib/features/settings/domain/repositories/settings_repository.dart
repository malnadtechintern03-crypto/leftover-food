import '../entities/app_settings.dart';

/// Repository interface for application settings
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<bool> hasSeededInitialData();
  Future<void> setSeededInitialData(bool seeded);
}

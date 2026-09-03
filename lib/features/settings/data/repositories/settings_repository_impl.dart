import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/app_settings_model.dart';

/// Concrete implementation of SettingsRepository
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl(this._localDataSource);

  @override
  Future<AppSettings> getSettings() async {
    return await _localDataSource.getSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final model = AppSettingsModel.fromEntity(settings);
    await _localDataSource.saveSettings(model);
  }

  @override
  Future<bool> hasSeededInitialData() async {
    return await _localDataSource.hasSeededInitialData();
  }

  @override
  Future<void> setSeededInitialData(bool seeded) async {
    await _localDataSource.setSeededInitialData(seeded);
  }
}

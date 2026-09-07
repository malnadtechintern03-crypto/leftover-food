import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

/// UseCase to save modified user settings
class SaveSettingsUseCase {
  final SettingsRepository _repository;

  const SaveSettingsUseCase(this._repository);

  Future<void> call(AppSettings settings) async {
    await _repository.saveSettings(settings);
  }
}

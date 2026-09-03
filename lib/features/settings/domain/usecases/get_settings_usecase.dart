import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

/// UseCase to retrieve user settings
class GetSettingsUseCase {
  final SettingsRepository _repository;

  const GetSettingsUseCase(this._repository);

  Future<AppSettings> call() async {
    return await _repository.getSettings();
  }
}

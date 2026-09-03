import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/app_initializer.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';

/// SharedPreferences instance provider (overridden in tests or supplied by AppInitializer)
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return AppInitializer.instance.sharedPreferences;
});

/// Settings local data source provider
final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsLocalDataSourceImpl(prefs);
});

/// Settings repository provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dataSource = ref.watch(settingsLocalDataSourceProvider);
  return SettingsRepositoryImpl(dataSource);
});

/// GetSettingsUseCase provider
final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return GetSettingsUseCase(repository);
});

/// SaveSettingsUseCase provider
final saveSettingsUseCaseProvider = Provider<SaveSettingsUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SaveSettingsUseCase(repository);
});

/// StateNotifier controlling reactive AppSettings with race condition prevention
class SettingsController extends StateNotifier<AsyncValue<AppSettings>> {
  final GetSettingsUseCase _getSettingsUseCase;
  final SaveSettingsUseCase _saveSettingsUseCase;
  int _loadCounter = 0;

  SettingsController(
    this._getSettingsUseCase,
    this._saveSettingsUseCase,
  ) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final requestId = ++_loadCounter;
    try {
      final settings = await _getSettingsUseCase();
      if (requestId == _loadCounter && mounted) {
        state = AsyncValue.data(settings);
      }
    } catch (e, stack) {
      if (requestId == _loadCounter && mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _loadCounter++;
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(themeMode: mode);
    await _save(updated);
  }

  Future<void> updateExpiryWarningDays(int days) async {
    _loadCounter++;
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(expiryWarningDays: days);
    await _save(updated);
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    _loadCounter++;
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(notificationsEnabled: enabled);
    await _save(updated);
  }

  Future<void> updateReminderTime(TimeOfDay time) async {
    _loadCounter++;
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(
      reminderHour: time.hour,
      reminderMinute: time.minute,
    );
    await _save(updated);
  }

  Future<void> _save(AppSettings settings) async {
    state = AsyncValue.data(settings);
    try {
      await _saveSettingsUseCase(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<AppSettings>>((ref) {
  final getUseCase = ref.watch(getSettingsUseCaseProvider);
  final saveUseCase = ref.watch(saveSettingsUseCaseProvider);
  return SettingsController(getUseCase, saveUseCase);
});

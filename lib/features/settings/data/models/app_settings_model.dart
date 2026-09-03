import 'package:flutter/material.dart';
import '../../domain/entities/app_settings.dart';

/// Data model extending domain AppSettings with serialization support
class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    super.themeMode,
    super.expiryWarningDays,
    super.notificationsEnabled,
    super.reminderHour,
    super.reminderMinute,
  });

  factory AppSettingsModel.fromEntity(AppSettings entity) {
    return AppSettingsModel(
      themeMode: entity.themeMode,
      expiryWarningDays: entity.expiryWarningDays,
      notificationsEnabled: entity.notificationsEnabled,
      reminderHour: entity.reminderHour,
      reminderMinute: entity.reminderMinute,
    );
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      themeMode: _parseThemeMode(json['themeMode'] as String?),
      expiryWarningDays: json['expiryWarningDays'] as int? ?? 2,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      reminderHour: json['reminderHour'] as int? ?? 9,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'expiryWarningDays': expiryWarningDays,
      'notificationsEnabled': notificationsEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
    };
  }

  static ThemeMode _parseThemeMode(String? val) {
    if (val == 'dark') return ThemeMode.dark;
    if (val == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }
}

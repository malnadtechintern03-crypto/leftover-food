import 'package:flutter/material.dart';

/// Domain entity representing application-wide user preferences
class AppSettings {
  final ThemeMode themeMode;
  final int expiryWarningDays;
  final bool notificationsEnabled;
  final int reminderHour;
  final int reminderMinute;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.expiryWarningDays = 2,
    this.notificationsEnabled = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? expiryWarningDays,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      expiryWarningDays: expiryWarningDays ?? this.expiryWarningDays,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          expiryWarningDays == other.expiryWarningDays &&
          notificationsEnabled == other.notificationsEnabled &&
          reminderHour == other.reminderHour &&
          reminderMinute == other.reminderMinute;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      expiryWarningDays.hashCode ^
      notificationsEnabled.hashCode ^
      reminderHour.hashCode ^
      reminderMinute.hashCode;
}

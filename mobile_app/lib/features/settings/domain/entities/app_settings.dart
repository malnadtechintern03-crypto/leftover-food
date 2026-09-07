import 'package:flutter/material.dart';

/// Domain entity representing application-wide user preferences
class AppSettings {
  final ThemeMode themeMode;
  final int expiryWarningDays;
  final bool notificationsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int defaultReminderDays;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool dailySummaryEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.expiryWarningDays = 2,
    this.notificationsEnabled = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.defaultReminderDays = 3,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.dailySummaryEnabled = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? expiryWarningDays,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? defaultReminderDays,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? dailySummaryEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      expiryWarningDays: expiryWarningDays ?? this.expiryWarningDays,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      defaultReminderDays: defaultReminderDays ?? this.defaultReminderDays,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
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
          reminderMinute == other.reminderMinute &&
          defaultReminderDays == other.defaultReminderDays &&
          soundEnabled == other.soundEnabled &&
          vibrationEnabled == other.vibrationEnabled &&
          dailySummaryEnabled == other.dailySummaryEnabled;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      expiryWarningDays.hashCode ^
      notificationsEnabled.hashCode ^
      reminderHour.hashCode ^
      reminderMinute.hashCode ^
      defaultReminderDays.hashCode ^
      soundEnabled.hashCode ^
      vibrationEnabled.hashCode ^
      dailySummaryEnabled.hashCode;
}


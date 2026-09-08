/// Core application constants for FoodSave
class AppConstants {
  AppConstants._();

  static const String appName = 'Home Pantry';
  static const String appTagline = 'Smart Food & Expiry Manager';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'foodsave.db';
  static const int databaseVersion = 4;
  static const String foodTable = 'food_items';
  static const String shoppingTable = 'shopping_items';
  static const String wasteTable = 'waste_records';
  static const String budgetTable = 'budget_settings';
  static const String recipeFavoritesTable = 'recipe_favorites';
  static const String remindersTable = 'product_reminders';
  static const String syncQueueTable = 'sync_queue';

  // Settings Keys
  static const String keyThemeMode = 'settings_theme_mode';
  static const String keyExpiryWarningDays = 'settings_expiry_warning_days';
  static const String keyNotificationsEnabled = 'settings_notifications_enabled';
  static const String keyReminderHour = 'settings_reminder_hour';
  static const String keyReminderMinute = 'settings_reminder_minute';
  static const String keyHasSeededInitialData = 'app_has_seeded_initial_data';
  static const String keyMonthlyBudget = 'settings_monthly_budget';
  static const String budgetMonthlyLimitKey = 'settings_monthly_budget';
  static const String keyCurrencySymbol = 'settings_currency_symbol';
  static const String keyExpiryRemindersEnabled = 'settings_expiry_reminders_enabled';
  static const String keyDefaultReminderDays = 'settings_default_reminder_days';
  static const String keyExpiredNotificationsEnabled = 'settings_expired_notifications_enabled';
  static const String keyDailySummaryEnabled = 'settings_daily_summary_enabled';
  static const String keyNotificationSound = 'settings_notification_sound';
  static const String keySoundEnabled = 'settings_sound_enabled';
  static const String keyVibrationEnabled = 'settings_vibration_enabled';
  static const String keyDailySummaryHour = 'settings_daily_summary_hour';
  static const String keyDailySummaryMinute = 'settings_daily_summary_minute';

  // Defaults
  static const int defaultExpiryWarningDays = 7;
  static const int defaultReminderDays = 7;
  static const int defaultReminderHour = 9;
  static const int defaultReminderMinute = 0;
  static const double defaultMonthlyBudget = 5000.0;
  static const double defaultMonthlyBudgetINR = 5000.0;
  static const String defaultCurrencySymbol = '₹';
}

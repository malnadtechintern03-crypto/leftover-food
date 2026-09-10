import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/food_inventory/domain/entities/food_item.dart';

/// Service managing local push notifications, smart expiry alerts, low-stock reminders & recurring schedules
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Callback when user taps a product notification
  static void Function(String productId)? onProductNotificationTapped;

  NotificationService._init();

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }

    // Desktop/web safety check
    if (!_isMobilePlatform) {
      _isInitialized = true;
      return;
    }

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.startsWith('product:')) {
            final productId = payload.substring('product:'.length);
            onProductNotificationTapped?.call(productId);
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init warning: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (!_isMobilePlatform) return;
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (_) {}
  }

  /// Calculates a deterministic notification ID for a product and offset
  int getNotificationId(String productId, int offsetDays) {
    return ((productId.hashCode & 0x3FFFFFFF) * 31 + offsetDays).abs();
  }

  /// Schedules multiple reminders for a product before its expiration date
  Future<void> scheduleProductReminders({
    required FoodItem item,
    required List<int> reminderDaysBefore,
    DateTime? customReminderDate,
    int reminderHour = 9,
    int reminderMinute = 0,
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    if (!_isInitialized) await initialize();

    // Cancel existing scheduled notifications for this product first
    await cancelProductReminders(item.id);

    if (item.isConsumed || item.expiryDate == null) return;

    final expiry = item.expiryDate!;
    final now = DateTime.now();

    final androidDetails = AndroidNotificationDetails(
      'product_expiry_channel',
      'Product Expiration Reminders',
      channelDescription: 'Alerts scheduled before product expiration dates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundEnabled,
      ),
    );

    // Schedule standard interval reminders (e.g. 1d, 3d, 7d, 14d, 30d)
    for (final days in reminderDaysBefore) {
      final scheduledDate = DateTime(
        expiry.year,
        expiry.month,
        expiry.day - days,
        reminderHour,
        reminderMinute,
      );

      if (scheduledDate.isAfter(now)) {
        final notifId = getNotificationId(item.id, days);
        final title = days == 1
            ? 'Expiring Tomorrow: ${item.name}'
            : days == 0
                ? 'Expires Today: ${item.name}'
                : 'Expiration Reminder: ${item.name}';
        final body = days == 0
            ? '${item.name} (${item.category.displayName}) expires today! Please check it.'
            : '${item.name} expires in $days day(s). Remember to use or inspect it.';

        await _scheduleOrShow(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          details: notificationDetails,
          payload: 'product:${item.id}',
        );
      }
    }

    // Schedule custom reminder date if provided
    if (customReminderDate != null) {
      final customScheduled = DateTime(
        customReminderDate.year,
        customReminderDate.month,
        customReminderDate.day,
        reminderHour,
        reminderMinute,
      );
      if (customScheduled.isAfter(now)) {
        final notifId = getNotificationId(item.id, 999);
        await _scheduleOrShow(
          id: notifId,
          title: 'Custom Reminder: ${item.name}',
          body: 'Reminder for ${item.name} (Expires: ${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')})',
          scheduledDate: customScheduled,
          details: notificationDetails,
          payload: 'product:${item.id}',
        );
      }
    }
  }

  Future<void> _scheduleOrShow({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
    required String payload,
  }) async {
    if (!_isMobilePlatform) {
      debugPrint('Notification scheduled [simulated]: $title at $scheduledDate');
      return;
    }

    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('zonedSchedule exactAllowWhileIdle note: $e, falling back to inexact');
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e2) {
        debugPrint('zonedSchedule inexact fallback non-fatal note: $e2');
      }
    }
  }

  /// Cancels all potential scheduled reminders for a specific product
  Future<void> cancelProductReminders(String productId) async {
    if (!_isMobilePlatform) return;
    const commonOffsets = [0, 1, 3, 7, 14, 30, 999];
    for (final offset in commonOffsets) {
      await cancelNotification(getNotificationId(productId, offset));
    }
  }

  /// Sends or schedules daily expiration summary notification
  Future<void> showDailySummaryAlert({
    required int expiringSoonCount,
    required int expiredCount,
    bool soundEnabled = true,
  }) async {
    if (!_isInitialized) await initialize();
    if (expiringSoonCount == 0 && expiredCount == 0) return;

    final String title = 'Daily Expiration Summary 📋';
    final List<String> parts = [];
    if (expiredCount > 0) {
      parts.add('$expiredCount expired product(s)');
    }
    if (expiringSoonCount > 0) {
      parts.add('$expiringSoonCount expiring soon');
    }
    final String body = 'You have ${parts.join(" and ")}. Tap to review your inventory.';

    await showExpiryAlert(
      id: 999999,
      title: title,
      body: body,
      payload: 'daily_summary',
    );
  }

  /// Sends tailored alert for a grocery item expiring in 7d, 3d, 1d (tomorrow), or expired
  Future<void> scheduleSmartExpiryAlerts(FoodItem item) async {
    if (!_isInitialized) await initialize();
    if (item.isConsumed || item.expiryDate == null) {
      await cancelNotification(item.id.hashCode);
      return;
    }

    final days = item.daysUntilExpiry();
    String? title;
    String? body;

    if (days < 0) {
      title = 'Product Expired 🚫';
      body = '${item.name} expired ${days.abs()} day(s) ago. Check if still safe or discard.';
    } else if (days == 0) {
      title = 'Urgent: Expires Today 🔥';
      body = '${item.name} expires today! Check it now.';
    } else if (days == 1) {
      title = 'Expiring Tomorrow ⌛';
      body = '${item.name} expires tomorrow.';
    } else if (days == 3) {
      title = 'Expiring Soon ⌛';
      body = 'Your ${item.name} expires in 3 days.';
    } else if (days == 7) {
      title = 'Upcoming Expiry 📅';
      body = '${item.name} expires in 7 days.';
    }

    if (title != null && body != null) {
      await showExpiryAlert(
        id: item.id.hashCode,
        title: title,
        body: body,
        payload: 'product:${item.id}',
      );
    }
  }

  Future<void> showExpiryAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isMobilePlatform) {
      debugPrint('Local notification simulated: $title - $body');
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'product_expiry_channel',
      'Product Expiry Reminders',
      channelDescription: 'Smart alerts for products nearing expiration date',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails, payload: payload);
  }

  Future<void> showLowStockAlert({
    required int id,
    required String itemName,
    required double currentQty,
    required String unit,
  }) async {
    await showExpiryAlert(
      id: id,
      title: 'Low Stock Alert 📦',
      body: '$itemName is running low ($currentQty $unit left). Add to shopping list?',
    );
  }

  Future<void> showRecurringReminder({
    required int id,
    required String itemName,
  }) async {
    await showExpiryAlert(
      id: id,
      title: 'Time to Repurchase 🛒',
      body: 'Time to buy $itemName based on your routine schedule.',
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_isMobilePlatform) return;
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_isMobilePlatform) return;
    await _notificationsPlugin.cancelAll();
  }
}


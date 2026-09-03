import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/food_inventory/domain/entities/food_item.dart';

/// Service managing local push notifications, smart expiry alerts, low-stock reminders & recurring schedules
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

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
          // Handle notification response locally
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

  /// Sends tailored alert for a grocery item expiring in 7d, 3d, 1d (tomorrow), or expired
  Future<void> scheduleSmartExpiryAlerts(FoodItem item) async {
    if (!_isInitialized) await initialize();
    if (item.isConsumed) {
      await cancelNotification(item.id.hashCode);
      return;
    }

    final days = item.daysUntilExpiry();
    String? title;
    String? body;

    if (days < 0) {
      title = 'Grocery Expired 🚫';
      body = '${item.name} expired ${days.abs()} day(s) ago. Check if still safe or discard.';
    } else if (days == 0) {
      title = 'Urgent: Expires Today 🔥';
      body = '${item.name} expires today! Use it first in your meal.';
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
      );
    }
  }

  Future<void> showExpiryAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isMobilePlatform) {
      debugPrint('Local notification simulated: $title - $body');
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'grocery_expiry_channel',
      'Grocery Expiry Reminders',
      channelDescription: 'Smart alerts for groceries nearing expiration date',
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

    await _notificationsPlugin.show(id, title, body, notificationDetails);
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

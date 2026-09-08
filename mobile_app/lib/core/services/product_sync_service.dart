import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import 'admin_sync_service.dart';

class ProductSyncResult {
  final int syncedCount;
  final int pulledCount;
  final int failedCount;
  final String? lastError;

  const ProductSyncResult({
    required this.syncedCount,
    this.pulledCount = 0,
    required this.failedCount,
    this.lastError,
  });
}

class ProductSyncService {
  ProductSyncService._();
  static final ProductSyncService instance = ProductSyncService._();

  String _baseUrl = 'http://localhost:8000/api';

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
  }

  /// Resolve appropriate default host for Android emulator vs desktop/web
  String getDefaultBaseUrl() {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  /// Process all pending records in SQLite sync_queue table (Push to Admin)
  Future<ProductSyncResult> syncPendingQueue({String? customBaseUrl}) async {
    String effectiveBaseUrl = customBaseUrl ?? _baseUrl;
    if (customBaseUrl == null) {
      final discoveredAdmin = await AdminSyncService.getWorkingBaseUrl();
      if (discoveredAdmin != null && discoveredAdmin.isNotEmpty) {
        effectiveBaseUrl = '$discoveredAdmin/api';
      }
    }
    final db = await DatabaseHelper.instance.database;
    if (db == null) {
      return const ProductSyncResult(syncedCount: 0, failedCount: 0);
    }

    int synced = 0;
    int failed = 0;
    String? lastError;

    try {
      final pendingRows = await db.query(
        AppConstants.syncQueueTable,
        where: "status = 'pending'",
        orderBy: 'created_at ASC',
        limit: 50,
      );

      for (final row in pendingRows) {
        final id = row['id'] as int;
        final action = row['action'] as String;
        final entityType = row['entity_type'] as String;
        final payloadRaw = row['payload'] as String?;
        final retryCount = (row['retry_count'] as int?) ?? 0;

        if (payloadRaw == null && action != 'delete') {
          await db.delete(AppConstants.syncQueueTable, where: 'id = ?', whereArgs: [id]);
          continue;
        }

        try {
          bool success = false;
          if (entityType == 'product') {
            if (action == 'insert') {
              final uri = Uri.parse('$effectiveBaseUrl/add-product.php');
              final res = await http.post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: payloadRaw,
              ).timeout(const Duration(seconds: 8));
              if (res.statusCode == 200 || res.statusCode == 201) success = true;
            } else if (action == 'update') {
              final uri = Uri.parse('$effectiveBaseUrl/update-product.php');
              final res = await http.post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: payloadRaw,
              ).timeout(const Duration(seconds: 8));
              if (res.statusCode == 200) success = true;
            } else if (action == 'delete') {
              final entityId = row['entity_id'] as String;
              final uri = Uri.parse('$effectiveBaseUrl/delete-product.php?product_id=$entityId');
              final res = await http.delete(uri).timeout(const Duration(seconds: 8));
              if (res.statusCode == 200) success = true;
            }
          }

          if (success) {
            await db.delete(AppConstants.syncQueueTable, where: 'id = ?', whereArgs: [id]);
            synced++;
          } else {
            failed++;
            await db.update(
              AppConstants.syncQueueTable,
              {
                'retry_count': retryCount + 1,
                'last_error': 'Server returned non-200 status',
                'status': retryCount >= 5 ? 'failed' : 'pending',
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        } catch (err) {
          failed++;
          lastError = err.toString();
          await db.update(
            AppConstants.syncQueueTable,
            {
              'retry_count': retryCount + 1,
              'last_error': lastError,
              'status': retryCount >= 5 ? 'failed' : 'pending',
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    } catch (e) {
      lastError = e.toString();
    }

    return ProductSyncResult(
      syncedCount: synced,
      failedCount: failed,
      lastError: lastError,
    );
  }

  /// Pulls products from Admin Panel into local SQLite database
  Future<int> pullFromAdmin({String? customBaseUrl}) async {
    String effectiveBaseUrl = customBaseUrl ?? _baseUrl;
    if (customBaseUrl == null) {
      final discoveredAdmin = await AdminSyncService.getWorkingBaseUrl();
      if (discoveredAdmin != null && discoveredAdmin.isNotEmpty) {
        effectiveBaseUrl = '$discoveredAdmin/api';
      }
    }

    final db = await DatabaseHelper.instance.database;
    if (db == null) return 0;

    int pulled = 0;
    try {
      final uri = Uri.parse('$effectiveBaseUrl/inventory.php?limit=100&include_consumed=1');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final items = decoded['data'] as List;

          for (final raw in items) {
            if (raw is Map<String, dynamic>) {
              final id = raw['id']?.toString() ?? '';
              if (id.isEmpty) continue;

              final name = raw['name']?.toString() ?? 'Unnamed Product';
              final brand = raw['brand']?.toString();
              final barcode = raw['barcode']?.toString();
              final imagePath = raw['image_path']?.toString();
              final category = raw['category']?.toString() ?? 'Other Groceries';
              final subcategory = raw['subcategory']?.toString();
              final quantity = (raw['quantity'] as num?)?.toDouble() ?? 1.0;
              final unit = raw['unit']?.toString() ?? 'pieces';
              final purchasePrice = (raw['purchase_price'] as num?)?.toDouble();
              final purchaseDate = raw['purchase_date']?.toString() ?? DateTime.now().toIso8601String();
              final manufacturingDate = raw['manufacturing_date']?.toString();
              final expiryDate = raw['expiry_date']?.toString();
              final reminderDate = raw['reminder_date']?.toString();
              final reminderEnabled = (raw['reminder_enabled'] == true || raw['reminder_enabled'] == 1) ? 1 : 0;
              final reminderDaysBefore = raw['reminder_days_before']?.toString() ?? '7';
              final notificationId = (raw['notification_id'] as num?)?.toInt() ?? abs(id.hashCode);
              final expiryStatus = raw['calculated_status']?.toString() ?? raw['expiry_status']?.toString() ?? 'Safe';
              final storageLocation = raw['storage_location']?.toString() ?? 'pantry';
              final notes = raw['notes']?.toString();
              final isConsumed = (raw['is_consumed'] == true || raw['is_consumed'] == 1) ? 1 : 0;
              final isFavorite = (raw['is_favorite'] == true || raw['is_favorite'] == 1) ? 1 : 0;
              final createdAt = raw['created_at']?.toString() ?? DateTime.now().toIso8601String();
              final updatedAt = raw['updated_at']?.toString() ?? DateTime.now().toIso8601String();

              await db.rawInsert('''
                INSERT OR REPLACE INTO ${AppConstants.foodTable} (
                  id, name, brand, barcode, image_path, category, subcategory,
                  remaining_quantity, unit, purchase_date, manufacturing_date,
                  expiry_date, reminder_date, reminder_enabled, reminder_days_before,
                  notification_id, expiry_status, notes, is_consumed, created_at,
                  updated_at, price, storage_location, is_favorite
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
              ''', [
                id, name, brand, barcode, imagePath, category, subcategory,
                quantity, unit, purchaseDate, manufacturingDate,
                expiryDate, reminderDate, reminderEnabled, reminderDaysBefore,
                notificationId, expiryStatus, notes, isConsumed, createdAt,
                updatedAt, purchasePrice, storageLocation, isFavorite,
              ]);

              pulled++;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('ProductSyncService.pullFromAdmin note: $e');
    }

    return pulled;
  }

  /// Full two-way sync: pushes pending mobile queue and pulls remote catalog & inventory
  Future<ProductSyncResult> performFullSync({String? customBaseUrl}) async {
    final pushResult = await syncPendingQueue(customBaseUrl: customBaseUrl);
    final pulled = await pullFromAdmin(customBaseUrl: customBaseUrl);

    return ProductSyncResult(
      syncedCount: pushResult.syncedCount,
      pulledCount: pulled,
      failedCount: pushResult.failedCount,
      lastError: pushResult.lastError,
    );
  }
}

int abs(int v) => v < 0 ? -v : v;

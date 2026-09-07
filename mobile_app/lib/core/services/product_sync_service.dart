import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import 'admin_sync_service.dart';

class ProductSyncResult {
  final int syncedCount;
  final int failedCount;
  final String? lastError;

  const ProductSyncResult({
    required this.syncedCount,
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

  /// Process all pending records in SQLite sync_queue table
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
              final uri = Uri.parse('$effectiveBaseUrl/delete-reminder.php?product_id=$entityId');
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
}

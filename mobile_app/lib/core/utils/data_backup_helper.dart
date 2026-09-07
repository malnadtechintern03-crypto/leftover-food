import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../database/database_helper.dart';

/// Helper for local JSON backup and restore operations
class DataBackupHelper {
  static Future<String> generateBackupJson() async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) {
      throw Exception('Database unavailable');
    }

    final foodRows = await db.query(AppConstants.foodTable);
    final shoppingRows = await db.query(AppConstants.shoppingTable);
    final wasteRows = await db.query(AppConstants.wasteTable);

    final backupMap = {
      'app_name': AppConstants.appName,
      'schema_version': AppConstants.databaseVersion,
      'created_at': DateTime.now().toIso8601String(),
      'groceries': foodRows,
      'shopping_items': shoppingRows,
      'waste_records': wasteRows,
    };

    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  static Future<bool> restoreFromJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!decoded.containsKey('groceries') &&
          !decoded.containsKey('food_items')) {
        throw Exception('Invalid backup file format.');
      }

      final db = await DatabaseHelper.instance.database;
      if (db == null) throw Exception('Database unavailable');

      final groceriesList =
          (decoded['groceries'] ?? decoded['food_items']) as List<dynamic>? ?? [];
      final shoppingList =
          (decoded['shopping_items'] as List<dynamic>?) ?? [];
      final wasteList = (decoded['waste_records'] as List<dynamic>?) ?? [];

      await db.transaction((txn) async {
        // 1. Clear existing data
        await txn.delete(AppConstants.foodTable);
        await txn.delete(AppConstants.shoppingTable);
        await txn.delete(AppConstants.wasteTable);

        // 2. Insert groceries
        for (final item in groceriesList) {
          final map = Map<String, dynamic>.from(item as Map);
          await txn.insert(AppConstants.foodTable, map);
        }

        // 3. Insert shopping items
        for (final item in shoppingList) {
          final map = Map<String, dynamic>.from(item as Map);
          await txn.insert(AppConstants.shoppingTable, map);
        }

        // 4. Insert waste records
        for (final item in wasteList) {
          final map = Map<String, dynamic>.from(item as Map);
          await txn.insert(AppConstants.wasteTable, map);
        }
      });

      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      rethrow;
    }
  }
}

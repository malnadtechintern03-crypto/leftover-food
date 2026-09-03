import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/waste_repository.dart';
import '../models/waste_record_model.dart';

abstract class WasteLocalDataSource {
  Future<List<WasteRecordModel>> getWasteRecords();
  Future<void> insertWasteRecord(WasteRecordModel record);
  Future<WasteSummaryStats> getWasteSummaryStats();
  Future<void> clearAllWasteRecords();
}

class WasteLocalDataSourceImpl implements WasteLocalDataSource {
  final DatabaseHelper _dbHelper;
  static final List<WasteRecordModel> _memoryStore = [];

  WasteLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<WasteRecordModel>> getWasteRecords() async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        final results = await db.query(
          AppConstants.wasteTable,
          orderBy: 'wasted_at DESC',
        );
        return results.map((e) => WasteRecordModel.fromMap(e)).toList();
      }
      return List.from(_memoryStore)
        ..sort((a, b) => b.wastedAt.compareTo(a.wastedAt));
    } catch (e) {
      throw DatabaseException('Failed to fetch waste records: $e');
    }
  }

  @override
  Future<void> insertWasteRecord(WasteRecordModel record) async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.insert(AppConstants.wasteTable, record.toMap());
      }
      _memoryStore.add(record);
    } catch (e) {
      throw DatabaseException('Failed to insert waste record: $e');
    }
  }

  @override
  Future<WasteSummaryStats> getWasteSummaryStats() async {
    try {
      final records = await getWasteRecords();
      double totalCost = 0.0;
      final reasonMap = <String, int>{};
      final categoryMap = <String, int>{};
      final itemFrequency = <String, int>{};

      for (final r in records) {
        totalCost += (r.cost ?? 0.0);
        reasonMap[r.reason.label] = (reasonMap[r.reason.label] ?? 0) + 1;
        categoryMap[r.category.label] = (categoryMap[r.category.label] ?? 0) + 1;
        itemFrequency[r.name] = (itemFrequency[r.name] ?? 0) + 1;
      }

      String? mostWasted;
      int maxWasted = 0;
      itemFrequency.forEach((name, count) {
        if (count > maxWasted) {
          maxWasted = count;
          mostWasted = name;
        }
      });

      return WasteSummaryStats(
        totalWasteRecords: records.length,
        totalWastedCost: totalCost,
        wasteByReason: reasonMap,
        wasteByCategory: categoryMap,
        mostWastedItem: mostWasted,
      );
    } catch (e) {
      throw DatabaseException('Failed to calculate waste summary: $e');
    }
  }

  @override
  Future<void> clearAllWasteRecords() async {
    try {
      final db = await _dbHelper.database;
      if (db != null) {
        await db.delete(AppConstants.wasteTable);
      }
      _memoryStore.clear();
    } catch (e) {
      throw DatabaseException('Failed to clear waste records: $e');
    }
  }
}

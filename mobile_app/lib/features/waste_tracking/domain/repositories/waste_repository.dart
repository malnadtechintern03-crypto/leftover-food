import '../entities/waste_record.dart';

class WasteSummaryStats {
  final int totalWasteRecords;
  final double totalWastedCost;
  final Map<String, int> wasteByReason;
  final Map<String, int> wasteByCategory;
  final String? mostWastedItem;

  const WasteSummaryStats({
    this.totalWasteRecords = 0,
    this.totalWastedCost = 0.0,
    this.wasteByReason = const {},
    this.wasteByCategory = const {},
    this.mostWastedItem,
  });
}

abstract class WasteRepository {
  Future<List<WasteRecord>> getWasteRecords();
  Future<void> recordWaste(WasteRecord record);
  Future<WasteSummaryStats> getWasteSummaryStats();
  Future<void> clearAllWasteRecords();
}

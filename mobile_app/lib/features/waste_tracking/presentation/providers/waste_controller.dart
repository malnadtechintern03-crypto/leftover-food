import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/datasources/waste_local_datasource.dart';
import '../../data/models/waste_record_model.dart';
import '../../domain/entities/waste_record.dart';
import '../../domain/repositories/waste_repository.dart';

class WasteRepositoryImpl implements WasteRepository {
  final WasteLocalDataSource _localDataSource;

  WasteRepositoryImpl(this._localDataSource);

  @override
  Future<List<WasteRecord>> getWasteRecords() async {
    return await _localDataSource.getWasteRecords();
  }

  @override
  Future<void> recordWaste(WasteRecord record) async {
    final model = WasteRecordModel.fromEntity(record);
    await _localDataSource.insertWasteRecord(model);
  }

  @override
  Future<WasteSummaryStats> getWasteSummaryStats() async {
    return await _localDataSource.getWasteSummaryStats();
  }

  @override
  Future<void> clearAllWasteRecords() async {
    await _localDataSource.clearAllWasteRecords();
  }
}

final wasteLocalDataSourceProvider = Provider<WasteLocalDataSource>((ref) {
  return WasteLocalDataSourceImpl(DatabaseHelper.instance);
});

final wasteRepositoryProvider = Provider<WasteRepository>((ref) {
  final ds = ref.watch(wasteLocalDataSourceProvider);
  return WasteRepositoryImpl(ds);
});

class WasteState {
  final AsyncValue<List<WasteRecord>> records;
  final AsyncValue<WasteSummaryStats> stats;

  const WasteState({
    required this.records,
    required this.stats,
  });

  WasteState copyWith({
    AsyncValue<List<WasteRecord>>? records,
    AsyncValue<WasteSummaryStats>? stats,
  }) {
    return WasteState(
      records: records ?? this.records,
      stats: stats ?? this.stats,
    );
  }
}

class WasteController extends StateNotifier<WasteState> {
  final WasteRepository _repository;

  WasteController(this._repository)
      : super(const WasteState(
          records: AsyncValue.loading(),
          stats: AsyncValue.loading(),
        )) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(
      records: const AsyncValue.loading(),
      stats: const AsyncValue.loading(),
    );
    try {
      final records = await _repository.getWasteRecords();
      final stats = await _repository.getWasteSummaryStats();
      if (!mounted) return;
      state = state.copyWith(
        records: AsyncValue.data(records),
        stats: AsyncValue.data(stats),
      );
    } catch (e, stack) {
      if (!mounted) return;
      state = state.copyWith(
        records: AsyncValue.error(e, stack),
        stats: AsyncValue.error(e, stack),
      );
    }
  }

  Future<void> logWaste(WasteRecord record) async {
    await _repository.recordWaste(record);
    await loadData();
  }

  Future<void> clearAll() async {
    await _repository.clearAllWasteRecords();
    await loadData();
  }
}

final wasteControllerProvider =
    StateNotifierProvider<WasteController, WasteState>((ref) {
  final repo = ref.watch(wasteRepositoryProvider);
  return WasteController(repo);
});

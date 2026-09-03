import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../food_inventory/domain/entities/food_filter.dart';
import '../../../food_inventory/domain/entities/food_item.dart';
import '../../../food_inventory/domain/usecases/get_food_items_usecase.dart';
import '../../../food_inventory/presentation/providers/food_inventory_providers.dart';
import '../../../settings/presentation/providers/settings_controller.dart';

enum CalendarViewMode {
  month,
  week,
  day;

  String get displayName {
    switch (this) {
      case CalendarViewMode.month:
        return 'Month';
      case CalendarViewMode.week:
        return 'Week';
      case CalendarViewMode.day:
        return 'Day';
    }
  }
}

class ExpiryCalendarState {
  final DateTime selectedMonth;
  final DateTime selectedDate;
  final CalendarViewMode viewMode;
  final AsyncValue<List<FoodItem>> items;
  final int warningDays;

  ExpiryCalendarState({
    required this.selectedMonth,
    required this.selectedDate,
    this.viewMode = CalendarViewMode.month,
    required this.items,
    this.warningDays = 2,
  });

  static String dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Groups items by their expiration date key YYYY-MM-DD
  Map<String, List<FoodItem>> get itemsByDateKey {
    final map = <String, List<FoodItem>>{};
    final list = items.valueOrNull ?? [];
    for (final item in list) {
      final key = dateKey(item.expiryDate);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Returns items expiring on the currently selected date
  List<FoodItem> get itemsForSelectedDate {
    final key = dateKey(selectedDate);
    return itemsByDateKey[key] ?? [];
  }

  /// Returns items expiring on a specific date
  List<FoodItem> itemsForDate(DateTime date) {
    final key = dateKey(date);
    return itemsByDateKey[key] ?? [];
  }

  ExpiryCalendarState copyWith({
    DateTime? selectedMonth,
    DateTime? selectedDate,
    CalendarViewMode? viewMode,
    AsyncValue<List<FoodItem>>? items,
    int? warningDays,
  }) {
    return ExpiryCalendarState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
      items: items ?? this.items,
      warningDays: warningDays ?? this.warningDays,
    );
  }
}

class ExpiryCalendarController extends StateNotifier<ExpiryCalendarState> {
  final GetFoodItemsUseCase _getItemsUseCase;

  ExpiryCalendarController(
    this._getItemsUseCase,
    int initialWarningDays,
  ) : super(_createInitialState(initialWarningDays)) {
    loadEvents();
  }

  static ExpiryCalendarState _createInitialState(int warningDays) {
    final now = DateTime.now();
    return ExpiryCalendarState(
      selectedMonth: DateTime(now.year, now.month, 1),
      selectedDate: DateTime(now.year, now.month, now.day),
      viewMode: CalendarViewMode.month,
      items: const AsyncValue.loading(),
      warningDays: warningDays,
    );
  }

  Future<void> loadEvents() async {
    state = state.copyWith(items: const AsyncValue.loading());
    try {
      final items = await _getItemsUseCase(
        filter: const FoodFilter(includeConsumed: true),
        warningDays: state.warningDays,
      );
      if (!mounted) return;
      state = state.copyWith(items: AsyncValue.data(items));
    } catch (e, stack) {
      if (!mounted) return;
      state = state.copyWith(items: AsyncValue.error(e, stack));
    }
  }

  void selectDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final monthOfDate = DateTime(date.year, date.month, 1);
    state = state.copyWith(
      selectedDate: normalizedDate,
      selectedMonth: monthOfDate,
    );
  }

  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(
      selectedMonth: DateTime(now.year, now.month, 1),
      selectedDate: DateTime(now.year, now.month, now.day),
    );
  }

  void previousMonth() {
    if (state.viewMode == CalendarViewMode.month) {
      final prevMonth = DateTime(state.selectedMonth.year, state.selectedMonth.month - 1, 1);
      final newSelectedDate = DateTime(
        prevMonth.year,
        prevMonth.month,
        state.selectedDate.day.clamp(1, _daysInMonth(prevMonth.year, prevMonth.month)),
      );
      state = state.copyWith(
        selectedMonth: prevMonth,
        selectedDate: newSelectedDate,
      );
    } else if (state.viewMode == CalendarViewMode.week) {
      final newDate = state.selectedDate.subtract(const Duration(days: 7));
      selectDate(newDate);
    } else {
      final newDate = state.selectedDate.subtract(const Duration(days: 1));
      selectDate(newDate);
    }
  }

  void nextMonth() {
    if (state.viewMode == CalendarViewMode.month) {
      final nextMonth = DateTime(state.selectedMonth.year, state.selectedMonth.month + 1, 1);
      final newSelectedDate = DateTime(
        nextMonth.year,
        nextMonth.month,
        state.selectedDate.day.clamp(1, _daysInMonth(nextMonth.year, nextMonth.month)),
      );
      state = state.copyWith(
        selectedMonth: nextMonth,
        selectedDate: newSelectedDate,
      );
    } else if (state.viewMode == CalendarViewMode.week) {
      final newDate = state.selectedDate.add(const Duration(days: 7));
      selectDate(newDate);
    } else {
      final newDate = state.selectedDate.add(const Duration(days: 1));
      selectDate(newDate);
    }
  }

  void updateWarningDays(int days) {
    if (state.warningDays != days) {
      state = state.copyWith(warningDays: days);
      loadEvents();
    }
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}

final expiryCalendarControllerProvider =
    StateNotifierProvider<ExpiryCalendarController, ExpiryCalendarState>((ref) {
  final getItemsUseCase = ref.watch(getFoodItemsUseCaseProvider);
  final warningDays = ref.watch(
    settingsControllerProvider.select((s) => s.valueOrNull?.expiryWarningDays ?? 2),
  );

  return ExpiryCalendarController(getItemsUseCase, warningDays);
});

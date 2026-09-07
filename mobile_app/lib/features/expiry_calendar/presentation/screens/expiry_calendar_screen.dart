import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../providers/expiry_calendar_provider.dart';
import '../widgets/calendar_day_cell.dart';
import '../widgets/calendar_event_list.dart';
import '../widgets/calendar_header.dart';

class ExpiryCalendarScreen extends ConsumerWidget {
  const ExpiryCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final calendarState = ref.watch(expiryCalendarControllerProvider);
    final controller = ref.read(expiryCalendarControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expiry Calendar',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Grocery Item',
            onPressed: () => context.push(RoutePaths.addFood),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => controller.loadEvents(),
          ),
        ],
      ),
      body: calendarState.items.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ColorPalette.freshEmerald),
        ),
        error: (err, _) => ErrorStateView(
          message: err.toString(),
          onRetry: () => controller.loadEvents(),
        ),
        data: (_) {
          return RefreshIndicator(
            color: ColorPalette.freshEmerald,
            onRefresh: () => controller.loadEvents(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Calendar Header (Month / Nav / Today / Mode)
                  CalendarHeader(
                    selectedMonth: calendarState.selectedMonth,
                    selectedDate: calendarState.selectedDate,
                    viewMode: calendarState.viewMode,
                    onPrevious: controller.previousMonth,
                    onNext: controller.nextMonth,
                    onToday: controller.goToToday,
                    onViewModeChanged: controller.setViewMode,
                  ),

                  const SizedBox(height: 8),

                  // 2. Calendar View Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Days of the week header row
                        _buildDaysOfWeekHeader(isDark),

                        const SizedBox(height: 8),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                        ),
                        const SizedBox(height: 8),

                        // Grid based on selected view mode
                        if (calendarState.viewMode == CalendarViewMode.month)
                          _buildMonthGrid(calendarState, controller)
                        else if (calendarState.viewMode == CalendarViewMode.week)
                          _buildWeekGrid(calendarState, controller)
                        else
                          _buildDayView(calendarState, controller, isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Selected Date Grocery Items List
                  CalendarEventList(
                    selectedDate: calendarState.selectedDate,
                    items: calendarState.itemsForSelectedDate,
                    warningDays: calendarState.warningDays,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaysOfWeekHeader(bool isDark) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: days.map((day) {
        final isWeekend = day == 'Sun' || day == 'Sat';
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isWeekend
                    ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
                    : (isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid(
    ExpiryCalendarState state,
    ExpiryCalendarController controller,
  ) {
    final year = state.selectedMonth.year;
    final month = state.selectedMonth.month;

    // 1st day of month
    final firstDayOfMonth = DateTime(year, month, 1);
    // Weekday: Dart gives Monday=1 ... Sunday=7 -> convert to Sunday=0 ... Saturday=6
    final firstWeekday = firstDayOfMonth.weekday % 7;

    // Total days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Total days in previous month
    final daysInPrevMonth = DateTime(year, month, 0).day;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day);

    // Generate grid dates (42 cells = 6 weeks)
    final gridCells = <Widget>[];

    // Leading days from previous month
    for (int i = firstWeekday - 1; i >= 0; i--) {
      final dayNum = daysInPrevMonth - i;
      final cellDate = DateTime(year, month - 1, dayNum);
      final items = state.itemsForDate(cellDate);
      final isToday = cellDate.isAtSameMomentAs(today);
      final isSelected = cellDate.isAtSameMomentAs(selectedDay);

      gridCells.add(
        CalendarDayCell(
          date: cellDate,
          isCurrentMonth: false,
          isToday: isToday,
          isSelected: isSelected,
          items: items,
          warningDays: state.warningDays,
          onTap: () => controller.selectDate(cellDate),
        ),
      );
    }

    // Days in current month
    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(year, month, day);
      final items = state.itemsForDate(cellDate);
      final isToday = cellDate.isAtSameMomentAs(today);
      final isSelected = cellDate.isAtSameMomentAs(selectedDay);

      gridCells.add(
        CalendarDayCell(
          date: cellDate,
          isCurrentMonth: true,
          isToday: isToday,
          isSelected: isSelected,
          items: items,
          warningDays: state.warningDays,
          onTap: () => controller.selectDate(cellDate),
        ),
      );
    }

    // Trailing days from next month to complete rows (multiples of 7)
    final remainingCells = (7 - (gridCells.length % 7)) % 7;
    for (int day = 1; day <= remainingCells; day++) {
      final cellDate = DateTime(year, month + 1, day);
      final items = state.itemsForDate(cellDate);
      final isToday = cellDate.isAtSameMomentAs(today);
      final isSelected = cellDate.isAtSameMomentAs(selectedDay);

      gridCells.add(
        CalendarDayCell(
          date: cellDate,
          isCurrentMonth: false,
          isToday: isToday,
          isSelected: isSelected,
          items: items,
          warningDays: state.warningDays,
          onTap: () => controller.selectDate(cellDate),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 2,
      childAspectRatio: 0.9,
      children: gridCells,
    );
  }

  Widget _buildWeekGrid(
    ExpiryCalendarState state,
    ExpiryCalendarController controller,
  ) {
    final selected = state.selectedDate;
    final sundayOffset = selected.weekday % 7;
    final startOfWeek = DateTime(selected.year, selected.month, selected.day - sundayOffset);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day);

    final cells = <Widget>[];
    for (int i = 0; i < 7; i++) {
      final cellDate = startOfWeek.add(Duration(days: i));
      final items = state.itemsForDate(cellDate);
      final isToday = cellDate.isAtSameMomentAs(today);
      final isSelected = cellDate.isAtSameMomentAs(selectedDay);

      cells.add(
        Expanded(
          child: CalendarDayCell(
            date: cellDate,
            isCurrentMonth: cellDate.month == state.selectedMonth.month,
            isToday: isToday,
            isSelected: isSelected,
            items: items,
            warningDays: state.warningDays,
            onTap: () => controller.selectDate(cellDate),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: cells,
    );
  }

  Widget _buildDayView(
    ExpiryCalendarState state,
    ExpiryCalendarController controller,
    bool isDark,
  ) {
    final selected = state.selectedDate;
    final now = DateTime.now();
    final isToday = selected.year == now.year && selected.month == now.month && selected.day == now.day;
    final items = state.itemsForSelectedDate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isToday
                  ? ColorPalette.freshEmerald
                  : (isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${selected.day}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isToday
                        ? Colors.white
                        : (isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary),
                  ),
                ),
                Text(
                  isToday ? 'Today' : 'Selected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? Colors.white.withValues(alpha: 0.9)
                        : (isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${items.length} grocery ${items.length == 1 ? 'item' : 'items'} expiring',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  items.isEmpty
                      ? 'No items tracked for expiration on this date'
                      : 'Review items below and consume before expiry',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

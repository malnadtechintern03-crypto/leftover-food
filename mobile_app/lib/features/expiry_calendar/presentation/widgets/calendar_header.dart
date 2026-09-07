import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/color_palette.dart';
import '../providers/expiry_calendar_provider.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime selectedDate;
  final CalendarViewMode viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<CalendarViewMode> onViewModeChanged;

  const CalendarHeader({
    super.key,
    required this.selectedMonth,
    required this.selectedDate,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onViewModeChanged,
  });

  String _formatTitle() {
    switch (viewMode) {
      case CalendarViewMode.month:
        return DateFormat.yMMMM().format(selectedMonth);
      case CalendarViewMode.week:
        final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        if (startOfWeek.month == endOfWeek.month) {
          return '${DateFormat.MMMM().format(startOfWeek)} ${startOfWeek.day}–${endOfWeek.day}, ${startOfWeek.year}';
        }
        return '${DateFormat.MMM().format(startOfWeek)} ${startOfWeek.day} – ${DateFormat.MMM().format(endOfWeek)} ${endOfWeek.day}';
      case CalendarViewMode.day:
        return DateFormat.yMMMMd().format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Month / Period Title
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatTitle(),
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // "Today" Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToday,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? ColorPalette.freshEmerald.withValues(alpha: 0.15)
                          : ColorPalette.freshEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ColorPalette.freshEmerald.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.today_rounded,
                          size: 13,
                          color: ColorPalette.freshEmerald,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? ColorPalette.freshEmerald
                                : ColorPalette.freshEmeraldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Navigation Arrow Controls (< and >)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      tooltip: 'Previous period',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: onPrevious,
                    ),
                    Container(
                      width: 1,
                      height: 18,
                      color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      tooltip: 'Next period',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: onNext,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // View Mode Selector Segmented Bar (Month / Week / Day)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
              ),
            ),
            child: Row(
              children: CalendarViewMode.values.map((mode) {
                final isSelected = viewMode == mode;
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onViewModeChanged(mode),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? ColorPalette.darkCard : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            mode.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? ColorPalette.freshEmerald
                                  : (isDark
                                      ? ColorPalette.darkTextSecondary
                                      : ColorPalette.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

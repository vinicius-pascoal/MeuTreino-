import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/utils/date_key.dart';

class AttendanceCalendar extends StatelessWidget {
  final DateTime visibleMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Set<String> completedDateKeys;
  final Set<int> expectedWeekDays;
  final DateTime? trackingStartDate;
  final bool isMonthDataReady;
  final bool compact;

  const AttendanceCalendar({
    super.key,
    required this.visibleMonth,
    required this.onMonthChanged,
    required this.completedDateKeys,
    required this.expectedWeekDays,
    required this.trackingStartDate,
    required this.isMonthDataReady,
    this.compact = false,
  });

  DateTime _monthAnchor(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _gridStart(DateTime month) {
    final firstDayOfMonth = _monthAnchor(month);
    return firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
  }

  List<DateTime> _visibleDays(DateTime month) {
    final start = _gridStart(month);
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  bool _hasWorkout(DateTime date) {
    return completedDateKeys.contains(DateKey.fromDate(date));
  }

  bool _isTrackedDay(DateTime date) {
    final start = trackingStartDate;
    if (start == null) return true;

    return !DateKey.normalize(date).isBefore(DateKey.normalize(start));
  }

  bool _isMissedDay(DateTime date, {required bool inCurrentMonth}) {
    if (!inCurrentMonth || !isMonthDataReady || expectedWeekDays.isEmpty) {
      return false;
    }

    final normalizedDate = DateKey.normalize(date);
    final today = DateKey.normalize(DateTime.now());

    if (!normalizedDate.isBefore(today)) return false;
    if (!_isTrackedDay(normalizedDate)) return false;
    if (!expectedWeekDays.contains(normalizedDate.weekday)) return false;

    return !_hasWorkout(normalizedDate);
  }

  _CalendarDayStyle _resolveStyle(DateTime day) {
    final normalizedDay = DateKey.normalize(day);
    final normalizedMonth = _monthAnchor(visibleMonth);
    final inCurrentMonth =
        normalizedDay.month == normalizedMonth.month &&
        normalizedDay.year == normalizedMonth.year;
    final isToday = DateKey.isSameDay(normalizedDay, DateTime.now());
    final hasWorkout = inCurrentMonth && _hasWorkout(normalizedDay);
    final isMissed = _isMissedDay(normalizedDay, inCurrentMonth: inCurrentMonth);

    if (hasWorkout) {
      return _CalendarDayStyle(
        backgroundColor: AppThemeColors.primary.withValues(alpha: 0.16),
        borderColor: AppThemeColors.primary.withValues(alpha: 0.3),
        textColor: AppThemeColors.primaryStrong,
        fontWeight: FontWeight.w800,
        inCurrentMonth: true,
      );
    }

    if (isMissed) {
      return _CalendarDayStyle(
        backgroundColor: AppThemeColors.danger.withValues(alpha: 0.16),
        borderColor: AppThemeColors.danger.withValues(alpha: 0.24),
        textColor: AppThemeColors.danger,
        fontWeight: FontWeight.w800,
        inCurrentMonth: true,
      );
    }

    if (isToday && inCurrentMonth) {
      return _CalendarDayStyle(
        backgroundColor: AppThemeColors.surfaceSoft.withValues(alpha: 0.9),
        borderColor: AppThemeColors.outlineStrong,
        textColor: Colors.white,
        fontWeight: FontWeight.w800,
        inCurrentMonth: true,
      );
    }

    return _CalendarDayStyle(
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      textColor: inCurrentMonth
          ? Colors.white
          : AppThemeColors.textSoft.withValues(alpha: 0.45),
      fontWeight: FontWeight.w500,
      inCurrentMonth: inCurrentMonth,
    );
  }

  void _goToPreviousMonth() {
    onMonthChanged(DateTime(visibleMonth.year, visibleMonth.month - 1, 1));
  }

  void _goToNextMonth() {
    onMonthChanged(DateTime(visibleMonth.year, visibleMonth.month + 1, 1));
  }

  @override
  Widget build(BuildContext context) {
    final days = _visibleDays(visibleMonth);
    final monthLabel = DateFormat.yMMMM('pt_BR').format(visibleMonth);

    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 13 : 16,
          compact ? 12 : 16,
          compact ? 13 : 16,
          compact ? 12 : 14,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boundedHeight =
                constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final compactCalendar =
                compact || (boundedHeight && constraints.maxHeight < 330);
            final headerGap = compactCalendar ? 9.0 : 14.0;
            final weekdayGap = compactCalendar ? 6.0 : 9.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalendarHeader(
                  monthLabel: _capitalize(monthLabel),
                  compact: compactCalendar,
                  onPreviousMonth: _goToPreviousMonth,
                  onNextMonth: _goToNextMonth,
                ),
                SizedBox(height: headerGap),
                _WeekdayLabels(compact: compactCalendar),
                SizedBox(height: weekdayGap),
                if (boundedHeight)
                  Expanded(
                    child: _AdaptiveCalendarGrid(
                      days: days,
                      compact: compactCalendar,
                      resolveStyle: _resolveStyle,
                    ),
                  )
                else
                  _NaturalCalendarGrid(
                    days: days,
                    compact: compactCalendar,
                    resolveStyle: _resolveStyle,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _CalendarHeader extends StatelessWidget {
  final String monthLabel;
  final bool compact;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _CalendarHeader({
    required this.monthLabel,
    required this.compact,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frequencia do mes',
                style: theme.textTheme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: compact ? 3 : 5),
              Text(
                monthLabel,
                style: compact
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _CalendarNavButton(
          tooltip: 'Mes anterior',
          icon: Icons.chevron_left_rounded,
          onTap: onPreviousMonth,
          compact: compact,
        ),
        SizedBox(width: compact ? 6 : 8),
        _CalendarNavButton(
          tooltip: 'Proximo mes',
          icon: Icons.chevron_right_rounded,
          onTap: onNextMonth,
          compact: compact,
        ),
      ],
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  final bool compact;

  const _WeekdayLabels({required this.compact});

  static const _weekLabels = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sab',
    'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _weekLabels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: AppThemeColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 10 : 12,
                height: 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

typedef _CalendarStyleResolver = _CalendarDayStyle Function(DateTime day);

class _AdaptiveCalendarGrid extends StatelessWidget {
  final List<DateTime> days;
  final bool compact;
  final _CalendarStyleResolver resolveStyle;

  const _AdaptiveCalendarGrid({
    required this.days,
    required this.compact,
    required this.resolveStyle,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = compact ? 4.0 : 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - (spacing * 6)) / 7;
        final rawCellHeight = (constraints.maxHeight - (spacing * 5)) / 6;
        final cellHeight = rawCellHeight.clamp(20.0, compact ? 48.0 : 56.0);
        final childAspectRatio = cellWidth / cellHeight;

        return _CalendarGrid(
          days: days,
          compact: compact,
          spacing: spacing,
          childAspectRatio: childAspectRatio,
          resolveStyle: resolveStyle,
        );
      },
    );
  }
}

class _NaturalCalendarGrid extends StatelessWidget {
  final List<DateTime> days;
  final bool compact;
  final _CalendarStyleResolver resolveStyle;

  const _NaturalCalendarGrid({
    required this.days,
    required this.compact,
    required this.resolveStyle,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = compact ? 4.0 : 8.0;

    return _CalendarGrid(
      days: days,
      compact: compact,
      spacing: spacing,
      childAspectRatio: compact ? 1.05 : 0.9,
      shrinkWrap: true,
      resolveStyle: resolveStyle,
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<DateTime> days;
  final bool compact;
  final double spacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final _CalendarStyleResolver resolveStyle;

  const _CalendarGrid({
    required this.days,
    required this.compact,
    required this.spacing,
    required this.childAspectRatio,
    required this.resolveStyle,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: shrinkWrap,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        final style = resolveStyle(day);

        return _CalendarDayCell(
          day: day,
          style: style,
          compact: compact,
        );
      },
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const _CalendarNavButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 42.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppThemeColors.outline),
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 20 : 24),
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final _CalendarDayStyle style;
  final bool compact;

  const _CalendarDayCell({
    required this.day,
    required this.style,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 11 : 14),
        border: Border.all(color: style.borderColor),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: style.textColor,
                fontSize: compact ? 12 : 14,
                fontWeight: style.fontWeight,
                height: 1,
              ),
            ),
          ),
          if (style.showDot)
            Positioned(
              bottom: compact ? 4 : 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: compact ? 5 : 6,
                  height: compact ? 5 : 6,
                  decoration: BoxDecoration(
                    color: style.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarDayStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final FontWeight fontWeight;
  final bool showDot;
  final Color dotColor;
  final bool inCurrentMonth;

  const _CalendarDayStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.fontWeight,
    this.showDot = false,
    this.dotColor = Colors.transparent,
    required this.inCurrentMonth,
  });
}

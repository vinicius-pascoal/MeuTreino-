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

  const AttendanceCalendar({
    super.key,
    required this.visibleMonth,
    required this.onMonthChanged,
    required this.completedDateKeys,
    required this.expectedWeekDays,
    required this.trackingStartDate,
    required this.isMonthDataReady,
  });

  static const _weekLabels = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sab',
    'Dom',
  ];

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
        showDot: true,
        dotColor: AppThemeColors.primaryStrong,
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequencia do mes',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _capitalize(monthLabel),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                _CalendarNavButton(
                  tooltip: 'Mes anterior',
                  icon: Icons.chevron_left_rounded,
                  onTap: _goToPreviousMonth,
                ),
                const SizedBox(width: 8),
                _CalendarNavButton(
                  tooltip: 'Proximo mes',
                  icon: Icons.chevron_right_rounded,
                  onTap: _goToNextMonth,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: _weekLabels.map((label) {
                return Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppThemeColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                final style = _resolveStyle(day);

                return _CalendarDayCell(day: day, style: style);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _CalendarNavButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _CalendarNavButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeColors.outline),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final _CalendarDayStyle style;

  const _CalendarDayCell({required this.day, required this.style});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.borderColor),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: style.textColor,
                fontWeight: style.fontWeight,
              ),
            ),
          ),
          if (style.showDot)
            Positioned(
              bottom: 7,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
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

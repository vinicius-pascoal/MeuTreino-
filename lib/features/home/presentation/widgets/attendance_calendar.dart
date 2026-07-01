import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/utils/date_key.dart';
import '../../../workout_plan/models/workout_plan.dart';
import '../../../workout_session/models/workout_session_summary.dart';

class AttendanceCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final void Function(DateTime focusedDay) onPageChanged;
  final List<WorkoutSessionSummary> sessions;
  final WorkoutPlan? plan;

  const AttendanceCalendar({
    super.key,
    required this.focusedDay,
    required this.onPageChanged,
    required this.sessions,
    required this.plan,
  });

  bool _hasWorkout(DateTime date) {
    final key = DateKey.fromDate(date);
    return sessions.any((session) => session.workoutDateKey == key);
  }

  bool _isMissedDay(DateTime date) {
    final currentPlan = plan;

    if (currentPlan == null) return false;

    final today = DateKey.normalize(DateTime.now());
    final normalizedDate = DateKey.normalize(date);

    if (!normalizedDate.isBefore(today)) return false;

    final isExpectedTrainingDay = currentPlan.trainingWeekDays.contains(
      normalizedDate.weekday,
    );

    if (!isExpectedTrainingDay) return false;

    return !_hasWorkout(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: TableCalendar(
          locale: 'pt_BR',
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
          onPageChanged: onPageChanged,
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: Theme.of(context).textTheme.titleMedium!,
            leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: AppThemeColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
            weekendStyle: TextStyle(
              color: AppThemeColors.textSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          calendarStyle: const CalendarStyle(
            outsideTextStyle: TextStyle(color: AppThemeColors.textSoft),
            defaultTextStyle: TextStyle(color: Colors.white),
            weekendTextStyle: TextStyle(color: Colors.white),
            cellMargin: EdgeInsets.all(4),
            todayDecoration: BoxDecoration(color: Colors.transparent),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) => _buildDay(day),
            todayBuilder: (context, day, _) => _buildDay(day, isToday: true),
            outsideBuilder: (context, day, _) {
              return Opacity(opacity: 0.35, child: _buildDay(day));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDay(DateTime day, {bool isToday = false}) {
    final attended = _hasWorkout(day);
    final missed = _isMissedDay(day);

    Color? backgroundColor;
    Color borderColor = Colors.transparent;
    Color textColor = Colors.white;

    if (attended) {
      backgroundColor = AppThemeColors.primary.withValues(alpha: 0.16);
      borderColor = AppThemeColors.primary.withValues(alpha: 0.28);
      textColor = AppThemeColors.primaryStrong;
    } else if (missed) {
      backgroundColor = AppThemeColors.danger.withValues(alpha: 0.16);
      borderColor = AppThemeColors.danger.withValues(alpha: 0.24);
      textColor = AppThemeColors.danger;
    } else if (isToday) {
      backgroundColor = AppThemeColors.surfaceSoft.withValues(alpha: 0.9);
      borderColor = AppThemeColors.outlineStrong;
    }

    return Container(
      margin: const EdgeInsets.all(5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: isToday || attended || missed
              ? FontWeight.w800
              : FontWeight.normal,
        ),
      ),
    );
  }
}

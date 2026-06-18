import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/utils/date_key.dart';
import '../../../workout_session/models/workout_session_summary.dart';
import '../../../workout_plan/models/workout_plan.dart';

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
        padding: const EdgeInsets.all(12),
        child: TableCalendar(
          locale: 'pt_BR',
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
          onPageChanged: onPageChanged,
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildDay(day);
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildDay(day, isToday: true);
            },
            outsideBuilder: (context, day, focusedDay) {
              return Opacity(opacity: 0.35, child: _buildDay(day));
            },
          ),
        ),
      ),
    );
  }

  Widget? _buildDay(DateTime day, {bool isToday = false}) {
    final attended = _hasWorkout(day);
    final missed = _isMissedDay(day);

    Color? color;

    if (attended) {
      color = const Color(0xFF22C55E);
    } else if (missed) {
      color = const Color(0xFFEF4444);
    } else if (isToday) {
      color = const Color(0xFF334155);
    }

    return Container(
      margin: const EdgeInsets.all(5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: color == null ? Colors.white : Colors.white,
          fontWeight: isToday || attended || missed
              ? FontWeight.w800
              : FontWeight.normal,
        ),
      ),
    );
  }
}

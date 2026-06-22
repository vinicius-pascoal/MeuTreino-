import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/utils/date_key.dart';
import '../../workout_plan/data/workout_plan_service.dart';
import '../../workout_plan/models/workout_plan.dart';
import '../../workout_session/data/workout_session_service.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';

class AppHomeWidgetService {
  AppHomeWidgetService({
    WorkoutService? workoutService,
    WorkoutPlanService? workoutPlanService,
    WorkoutSessionService? workoutSessionService,
  }) : _workoutService = workoutService ?? WorkoutService(),
       _workoutPlanService = workoutPlanService ?? WorkoutPlanService(),
       _workoutSessionService = workoutSessionService ?? WorkoutSessionService();

  static const String androidTodayWorkoutWidgetName =
      'TodayWorkoutWidgetProvider';

  final WorkoutService _workoutService;
  final WorkoutPlanService _workoutPlanService;
  final WorkoutSessionService _workoutSessionService;

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> updateTodayWorkoutWidget({
    required String workoutName,
    required String workoutDescription,
    required bool trainedToday,
    String? currentWorkoutId,
  }) async {
    if (!_isSupportedPlatform) return;

    await HomeWidget.saveWidgetData<String>(
      'today_workout_name',
      workoutName,
    );
    await HomeWidget.saveWidgetData<String>(
      'today_workout_description',
      workoutDescription,
    );
    await HomeWidget.saveWidgetData<bool>('trained_today', trainedToday);
    await HomeWidget.saveWidgetData<String>(
      'current_workout_id',
      currentWorkoutId ?? '',
    );

    await HomeWidget.updateWidget(name: androidTodayWorkoutWidgetName);
  }

  Future<void> updateWeeklySummaryWidgetData({
    required int weeklyDone,
    required int weeklyExpected,
  }) async {
    if (!_isSupportedPlatform) return;

    await HomeWidget.saveWidgetData<int>('weekly_done', weeklyDone);
    await HomeWidget.saveWidgetData<int>('weekly_expected', weeklyExpected);
    await HomeWidget.saveWidgetData<String>(
      'weekly_status_text',
      '$weeklyDone/$weeklyExpected treinos na semana',
    );
  }

  Future<void> clearTodayWorkoutWidget() async {
    if (!_isSupportedPlatform) return;

    await updateTodayWorkoutWidget(
      workoutName: 'Nenhum treino configurado',
      workoutDescription: 'Abra o app para configurar sua sequencia ABC',
      trainedToday: false,
      currentWorkoutId: '',
    );
    await updateWeeklySummaryWidgetData(weeklyDone: 0, weeklyExpected: 0);
  }

  Future<void> syncFromAppState() async {
    if (!_isSupportedPlatform) return;

    try {
      final workouts = await _workoutService.getWorkoutsOnce();
      final plan = await _workoutPlanService.getPlanOnce();

      final currentWorkout = _findCurrentWorkout(plan: plan, workouts: workouts);
      final today = DateTime.now();
      final todaySessions = await _workoutSessionService.getSessionsBetween(
        start: today,
        end: today,
      );
      final trainedToday = todaySessions.any(
        (session) => session.workoutDateKey == DateKey.fromDate(today),
      );

      final weekStart = _startOfWeek(today);
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weeklySessions = await _workoutSessionService.getSessionsBetween(
        start: weekStart,
        end: weekEnd,
      );
      final weeklyDone = weeklySessions
          .map((session) => session.workoutDateKey)
          .toSet()
          .length;
      final weeklyExpected = plan?.trainingWeekDays.length ?? 0;

      await updateTodayWorkoutWidget(
        workoutName: currentWorkout?.name ?? 'Nenhum treino configurado',
        workoutDescription: _resolveWorkoutDescription(currentWorkout),
        trainedToday: trainedToday,
        currentWorkoutId: currentWorkout?.id,
      );
      await updateWeeklySummaryWidgetData(
        weeklyDone: weeklyDone,
        weeklyExpected: weeklyExpected,
      );
    } catch (error, stackTrace) {
      debugPrint('AppHomeWidgetService sync error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Workout? _findCurrentWorkout({
    required WorkoutPlan? plan,
    required List<Workout> workouts,
  }) {
    final workoutId = plan?.currentWorkoutId;
    if (workoutId == null) return null;

    for (final workout in workouts) {
      if (workout.id == workoutId) {
        return workout;
      }
    }

    return null;
  }

  String _resolveWorkoutDescription(Workout? workout) {
    if (workout == null) {
      return 'Abra o app para configurar sua sequencia ABC';
    }

    if (workout.description.trim().isEmpty) {
      return 'Abra o app para ver os detalhes do treino de hoje';
    }

    return workout.description.trim();
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateKey.normalize(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }
}

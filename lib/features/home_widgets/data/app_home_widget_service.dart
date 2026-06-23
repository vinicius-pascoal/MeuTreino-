import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/utils/date_key.dart';
import '../../workout_plan/data/workout_plan_service.dart';
import '../../workout_plan/models/workout_plan.dart';
import '../../workout_session/data/workout_session_service.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';

const _defaultWorkoutName = 'Nenhum treino configurado';
const _defaultWorkoutDescription =
    'Abra o app para configurar sua sequencia ABC';
const _defaultWorkoutEmptyDescription =
    'Abra o app para ver os detalhes do treino de hoje';

class AppHomeWidgetState {
  final String workoutName;
  final String workoutDescription;
  final bool trainedToday;
  final String? currentWorkoutId;
  final int weeklyDone;
  final int weeklyExpected;

  const AppHomeWidgetState({
    required this.workoutName,
    required this.workoutDescription,
    required this.trainedToday,
    required this.currentWorkoutId,
    required this.weeklyDone,
    required this.weeklyExpected,
  });

  const AppHomeWidgetState.empty()
    : workoutName = _defaultWorkoutName,
      workoutDescription = _defaultWorkoutDescription,
      trainedToday = false,
      currentWorkoutId = '',
      weeklyDone = 0,
      weeklyExpected = 0;

  String get weeklyStatusText => '$weeklyDone/$weeklyExpected treinos na semana';

  String get todayStatusText => trainedToday ? 'Concluido hoje' : 'Pendente';

  int get weeklyRemaining {
    final remaining = weeklyExpected - weeklyDone;
    return remaining < 0 ? 0 : remaining;
  }

  int get weeklyCompletionRate {
    if (weeklyExpected <= 0) return 0;

    final value = ((weeklyDone / weeklyExpected) * 100).round();
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  String get fingerprint {
    return [
      workoutName,
      workoutDescription,
      trainedToday.toString(),
      currentWorkoutId ?? '',
      weeklyDone.toString(),
      weeklyExpected.toString(),
    ].join('|');
  }
}

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
  static const String androidTodayWorkoutCompactWidgetName =
      'TodayWorkoutCompactWidgetProvider';
  static const String androidWeeklyFrequencyWidgetName =
      'WeeklyFrequencyWidgetProvider';

  final WorkoutService _workoutService;
  final WorkoutPlanService _workoutPlanService;
  final WorkoutSessionService _workoutSessionService;

  bool get isSupportedPlatform {
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
    if (!isSupportedPlatform) return;

    await _saveTodayWorkoutData(
      workoutName: workoutName,
      workoutDescription: workoutDescription,
      trainedToday: trainedToday,
      currentWorkoutId: currentWorkoutId,
    );
    await _refreshWidget();
  }

  Future<void> updateWeeklySummaryWidgetData({
    required int weeklyDone,
    required int weeklyExpected,
  }) async {
    if (!isSupportedPlatform) return;

    await _saveWeeklySummaryData(
      weeklyDone: weeklyDone,
      weeklyExpected: weeklyExpected,
    );
    await _refreshWidget();
  }

  Future<void> clearTodayWorkoutWidget() async {
    await clearWidgets();
  }

  Future<void> clearWidgets() async {
    await syncWidgetState(const AppHomeWidgetState.empty());
  }

  Future<void> syncWidgetState(AppHomeWidgetState state) async {
    if (!isSupportedPlatform) return;

    await Future.wait([
      _saveTodayWorkoutData(
        workoutName: state.workoutName,
        workoutDescription: state.workoutDescription,
        trainedToday: state.trainedToday,
        currentWorkoutId: state.currentWorkoutId,
      ),
      _saveWeeklySummaryData(
        weeklyDone: state.weeklyDone,
        weeklyExpected: state.weeklyExpected,
      ),
    ]);
    await _refreshWidget();
  }

  Future<void> syncFromAppState() async {
    if (!isSupportedPlatform) return;

    try {
      final state = await buildStateFromAppState();
      await syncWidgetState(state);
    } catch (error, stackTrace) {
      debugPrint('AppHomeWidgetService sync error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<AppHomeWidgetState> buildStateFromAppState() async {
    final workouts = await _workoutService.getWorkoutsOnce();
    final plan = await _workoutPlanService.getPlanOnce();

    final currentWorkout = _findCurrentWorkout(plan: plan, workouts: workouts);
    final today = DateTime.now();
    final todaySessions = await _workoutSessionService.getSessionsBetween(
      start: today,
      end: today,
    );
    final trainedToday = todaySessions.isNotEmpty;

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

    return AppHomeWidgetState(
      workoutName: currentWorkout?.name ?? _defaultWorkoutName,
      workoutDescription: _resolveWorkoutDescription(currentWorkout),
      trainedToday: trainedToday,
      currentWorkoutId: currentWorkout?.id,
      weeklyDone: weeklyDone,
      weeklyExpected: weeklyExpected,
    );
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
      return _defaultWorkoutDescription;
    }

    if (workout.description.trim().isEmpty) {
      return _defaultWorkoutEmptyDescription;
    }

    return workout.description.trim();
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateKey.normalize(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  Future<void> _saveTodayWorkoutData({
    required String workoutName,
    required String workoutDescription,
    required bool trainedToday,
    String? currentWorkoutId,
  }) async {
    final statusText = trainedToday ? 'Concluido hoje' : 'Pendente';

    await Future.wait([
      HomeWidget.saveWidgetData<String>('today_workout_name', workoutName),
      HomeWidget.saveWidgetData<String>(
        'today_workout_description',
        workoutDescription,
      ),
      HomeWidget.saveWidgetData<bool>('trained_today', trainedToday),
      HomeWidget.saveWidgetData<String>('today_status_text', statusText),
      HomeWidget.saveWidgetData<String>(
        'current_workout_id',
        currentWorkoutId ?? '',
      ),
    ]);
  }

  Future<void> _saveWeeklySummaryData({
    required int weeklyDone,
    required int weeklyExpected,
  }) async {
    final remaining = weeklyExpected - weeklyDone < 0
        ? 0
        : weeklyExpected - weeklyDone;
    final rate = weeklyExpected <= 0
        ? 0
        : (((weeklyDone / weeklyExpected) * 100).round()).clamp(0, 100);

    await Future.wait([
      HomeWidget.saveWidgetData<int>('weekly_done', weeklyDone),
      HomeWidget.saveWidgetData<int>('weekly_expected', weeklyExpected),
      HomeWidget.saveWidgetData<int>('weekly_remaining', remaining),
      HomeWidget.saveWidgetData<int>('weekly_completion_rate', rate),
      HomeWidget.saveWidgetData<String>(
        'weekly_status_text',
        '$weeklyDone/$weeklyExpected treinos na semana',
      ),
    ]);
  }

  Future<void> _refreshWidget() async {
    await Future.wait([
      HomeWidget.updateWidget(name: androidTodayWorkoutWidgetName),
      HomeWidget.updateWidget(name: androidTodayWorkoutCompactWidgetName),
      HomeWidget.updateWidget(name: androidWeeklyFrequencyWidgetName),
    ]);
  }
}

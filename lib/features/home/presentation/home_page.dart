import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/widgets/app_background.dart';
import '../../auth/data/auth_service.dart';
import '../../home_widgets/data/app_home_widget_service.dart';
import '../../workout_plan/data/workout_plan_service.dart';
import '../../workout_plan/models/workout_plan.dart';
import '../../workout_plan/presentation/workout_plan_page.dart';
import '../../workout_session/data/workout_session_service.dart';
import '../../workout_session/models/workout_session_summary.dart';
import '../../workout_session/presentation/workout_session_page.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';
import 'widgets/attendance_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  final _authService = AuthService();
  final _workoutService = WorkoutService();
  final _planService = WorkoutPlanService();
  final _sessionService = WorkoutSessionService();
  final _homeWidgetService = AppHomeWidgetService();
  late final Stream<List<Workout>> _workoutsStream;
  late final Stream<WorkoutPlan?> _planStream;
  late Stream<List<WorkoutSessionSummary>> _sessionsStream;
  final Map<String, List<WorkoutSessionSummary>> _sessionCacheByMonth = {};

  DateTime _visibleMonth = _monthAnchor(DateTime.now());
  String? _lastWidgetPayload;
  bool _skippingWorkout = false;

  static DateTime _monthAnchor(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  @override
  void initState() {
    super.initState();
    _workoutsStream = _workoutService.watchWorkouts();
    _planStream = _planService.watchPlan();
    _sessionsStream = _buildSessionsStream(_visibleMonth);
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _logout() async {
    await _authService.logout();
  }

  Stream<List<WorkoutSessionSummary>> _buildSessionsStream(DateTime date) {
    final monthStart = _monthAnchor(date);
    final monthEnd = DateTime(date.year, date.month + 1, 0);

    return _sessionService.watchSessionsBetween(
      start: monthStart,
      end: monthEnd,
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

  String _monthCacheKey(DateTime date) => '${date.year}-${date.month}';

  DateTime get _monthStart =>
      DateTime(_visibleMonth.year, _visibleMonth.month, 1);

  DateTime get _monthEnd =>
      DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

  DateTime? _planTrackingStart(WorkoutPlan? plan) {
    final currentPlan = plan;

    if (currentPlan == null) return null;

    return currentPlan.trackingStartedAt ??
        currentPlan.createdAt ??
        currentPlan.updatedAt;
  }

  int _countExpectedDaysInMonth(WorkoutPlan? plan) {
    final currentPlan = plan;
    if (currentPlan == null || currentPlan.trainingWeekDays.isEmpty) {
      return 0;
    }

    final trackingStart = _planTrackingStart(currentPlan);
    var cursor = _monthStart;

    if (trackingStart != null) {
      final normalizedTrackingStart = DateTime(
        trackingStart.year,
        trackingStart.month,
        trackingStart.day,
      );

      if (normalizedTrackingStart.isAfter(_monthEnd)) {
        return 0;
      }

      if (normalizedTrackingStart.isAfter(cursor)) {
        cursor = normalizedTrackingStart;
      }
    }

    var total = 0;

    while (!cursor.isAfter(_monthEnd)) {
      if (currentPlan.trainingWeekDays.contains(cursor.weekday)) {
        total++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return total;
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _startWorkout(Workout workout) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutSessionPage(workout: workout)),
    );
  }

  Future<void> _skipWorkout(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pular treino de hoje?'),
          content: Text(
            'O ${workout.name} sera removido da vez atual e o proximo treino da sequencia passara a aparecer na home sem registrar treino concluido hoje.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Pular treino'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _skippingWorkout = true);

    try {
      final advanced = await _planService.advanceToNextWorkout();

      if (!mounted) return;

      if (!advanced) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nao foi possivel pular o treino porque a sequencia semanal ainda nao esta pronta.',
            ),
          ),
        );
        return;
      }

      await _homeWidgetService.syncFromAppState();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Treino pulado. Se houver outro treino na sequencia, ele ja aparece na home.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao pular treino: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _skippingWorkout = false);
      }
    }
  }

  void _syncHomeWidget({
    required Workout? currentWorkout,
    required bool trainedToday,
  }) {
    final workoutName = currentWorkout?.name ?? 'Nenhum treino configurado';
    final workoutDescription =
        currentWorkout?.description.trim().isNotEmpty == true
        ? currentWorkout!.description.trim()
        : 'Abra o app para configurar sua sequencia ABC';
    final payload =
        '$workoutName|$workoutDescription|$trainedToday|${currentWorkout?.id ?? ''}';

    if (_lastWidgetPayload == payload) return;

    _lastWidgetPayload = payload;
    _homeWidgetService.syncFromAppState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<Workout>>(
      stream: _workoutsStream,
      builder: (context, workoutsSnapshot) {
        final workouts = workoutsSnapshot.data ?? const <Workout>[];

        return StreamBuilder<WorkoutPlan?>(
          stream: _planStream,
          builder: (context, planSnapshot) {
            final plan = planSnapshot.data;
            final currentWorkout = _findCurrentWorkout(
              plan: plan,
              workouts: workouts,
            );

            return StreamBuilder<List<WorkoutSessionSummary>>(
              key: ValueKey(_monthCacheKey(_visibleMonth)),
              stream: _sessionsStream,
              builder: (context, sessionsSnapshot) {
                final currentMonthKey = _monthCacheKey(_visibleMonth);
                if (sessionsSnapshot.hasData) {
                  _sessionCacheByMonth[currentMonthKey] = sessionsSnapshot.data!;
                }
                final sessions =
                    sessionsSnapshot.data ??
                    _sessionCacheByMonth[currentMonthKey] ??
                    const <WorkoutSessionSummary>[];
                final todayKey = DateKey.fromDate(DateTime.now());
                final trainedToday = sessions.any(
                  (session) => session.workoutDateKey == todayKey,
                );
                final completedDateKeys = sessions
                    .map((session) => session.workoutDateKey)
                    .toSet();
                final trackingStartDate = _planTrackingStart(plan);
                final canSkipWorkout =
                    currentWorkout != null &&
                    !trainedToday &&
                    plan != null &&
                    plan.sequenceWorkoutIds.length > 1;
                _syncHomeWidget(
                  currentWorkout: currentWorkout,
                  trainedToday: trainedToday,
                );

                final expectedDays = _countExpectedDaysInMonth(plan);
                final attendanceRate = expectedDays == 0
                    ? 0
                    : ((sessions.length / expectedDays) * 100).round().clamp(
                        0,
                        100,
                      );

                return Scaffold(
                  extendBody: true,
                  body: AppBackground(
                    child: SafeArea(
                      bottom: false,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                        children: [
                          _HomeTopBar(onLogout: _logout),
                          const SizedBox(height: 26),
                          _TodayWorkoutCard(
                            workout: currentWorkout,
                            trainedToday: trainedToday,
                            isSkippingWorkout: _skippingWorkout,
                            showSkipAction: canSkipWorkout,
                            onConfigure: () =>
                                _openPage(const WorkoutPlanPage()),
                            onStart: currentWorkout == null
                                ? null
                                : _skippingWorkout
                                ? null
                                : () => _startWorkout(currentWorkout!),
                            onSkip: canSkipWorkout && !_skippingWorkout
                                ? () => _skipWorkout(currentWorkout!)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 320;
                              final itemWidth = isCompact
                                  ? (constraints.maxWidth - 12) / 2
                                  : (constraints.maxWidth - 24) / 3;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _MetricCard(
                                      label: 'No mes',
                                      value: '${sessions.length}',
                                      accent: AppThemeColors.primary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _MetricCard(
                                      label: 'Meta',
                                      value: '$expectedDays',
                                      accent: AppThemeColors.secondary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _MetricCard(
                                      label: 'Ritmo',
                                      value: '$attendanceRate%',
                                      accent: AppThemeColors.warning,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          AttendanceCalendar(
                            visibleMonth: _visibleMonth,
                            completedDateKeys: completedDateKeys,
                            expectedWeekDays:
                                plan?.trainingWeekDays.toSet() ??
                                const <int>{},
                            trackingStartDate: trackingStartDate,
                            isMonthDataReady:
                                planSnapshot.connectionState !=
                                    ConnectionState.waiting &&
                                (sessionsSnapshot.hasData ||
                                    _sessionCacheByMonth.containsKey(
                                      currentMonthKey,
                                    )),
                            onMonthChanged: (nextMonth) {
                              final nextVisibleMonth = _monthAnchor(nextMonth);
                              final monthChanged =
                                  nextVisibleMonth.year != _visibleMonth.year ||
                                  nextVisibleMonth.month != _visibleMonth.month;

                              setState(() {
                                _visibleMonth = nextVisibleMonth;
                                if (monthChanged) {
                                  _sessionsStream = _buildSessionsStream(
                                    nextVisibleMonth,
                                  );
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          const Wrap(
                            spacing: 5,
                            runSpacing: 10,
                            children: [
                              _LegendPill(
                                color: AppThemeColors.primary,
                                label: 'Treino concluido',
                              ),
                              _LegendPill(
                                color: AppThemeColors.danger,
                                label: 'Dia perdido',
                              ),
                              _LegendPill(
                                color: AppThemeColors.surfaceSoft,
                                label: 'Hoje',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final VoidCallback onLogout;

  const _HomeTopBar({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppThemeColors.outline),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 18,
                    color: AppThemeColors.primaryStrong,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'MeuTreino+',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Sair',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  final Workout? workout;
  final bool trainedToday;
  final bool isSkippingWorkout;
  final bool showSkipAction;
  final VoidCallback onConfigure;
  final VoidCallback? onStart;
  final VoidCallback? onSkip;

  const _TodayWorkoutCard({
    required this.workout,
    required this.trainedToday,
    required this.isSkippingWorkout,
    required this.showSkipAction,
    required this.onConfigure,
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final currentWorkout = workout;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemeColors.surfaceHigh.withValues(alpha: 0.98),
            AppThemeColors.surface.withValues(alpha: 0.94),
          ],
        ),
        border: Border.all(color: AppThemeColors.outlineStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: currentWorkout == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Treino do dia',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppThemeColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nenhuma sequencia configurada',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organize a ordem dos treinos para liberar a recomendacao diaria e deixar a rotina mais previsivel.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onConfigure,
                    icon: const Icon(Icons.calendar_view_week_rounded),
                    label: const Text('Configurar treino semanal'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Treino do dia',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppThemeColors.textMuted,
                          ),
                        ),
                      ),
                      _StatusPill(
                        label: trainedToday ? 'Concluido' : 'Pronto',
                        backgroundColor: trainedToday
                            ? AppThemeColors.primary.withValues(alpha: 0.14)
                            : AppThemeColors.secondary.withValues(alpha: 0.14),
                        textColor: trainedToday
                            ? AppThemeColors.primaryStrong
                            : AppThemeColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentWorkout.name,
                    style: theme.textTheme.headlineMedium,
                  ),
                  if (currentWorkout.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      currentWorkout.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (trainedToday)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppThemeColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppThemeColors.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppThemeColors.primaryStrong,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Treino de hoje registrado. Use o app para revisar os proximos passos da semana.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppThemeColors.primaryStrong,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onStart,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Iniciar treino'),
                          ),
                        ),
                        if (showSkipAction) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onSkip,
                              icon: const Icon(Icons.skip_next_rounded),
                              label: Text(
                                isSkippingWorkout
                                    ? 'Pulando...'
                                    : 'Pular treino',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(color: accent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: AppThemeColors.textSoft,
                  ),
                ],
              ),
              const Spacer(),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

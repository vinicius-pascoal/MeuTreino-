import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/navigation/app_navigation_state_service.dart';
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
  final _navigationStateService = AppNavigationStateService();
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

  Future<void> _openPage({
    required Widget page,
    required PersistedPageState pageState,
  }) async {
    await _navigationStateService.pushTrackedPage(
      context: context,
      pageState: pageState,
      builder: (_) => page,
    );
  }

  void _startWorkout(Workout workout) {
    unawaited(
      _navigationStateService.pushTrackedPage(
        context: context,
        pageState: PersistedPageState.workoutSession(workoutId: workout.id),
        builder: (_) => WorkoutSessionPage(workout: workout),
      ),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compactHeight = constraints.maxHeight < 740;
                          final compactWidth = constraints.maxWidth < 360;
                          final compactLayout = compactHeight || compactWidth;
                          final horizontalPadding = compactWidth ? 14.0 : 20.0;
                          final bottomPadding = compactHeight ? 116.0 : 132.0;
                          final verticalGap = compactLayout ? 8.0 : 12.0;

                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              compactLayout ? 10 : 16,
                              horizontalPadding,
                              bottomPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HomeTopBar(onLogout: _logout),
                                SizedBox(height: compactLayout ? 10 : 16),
                                _TodayWorkoutCard(
                                  workout: currentWorkout,
                                  trainedToday: trainedToday,
                                  isSkippingWorkout: _skippingWorkout,
                                  showSkipAction: canSkipWorkout,
                                  compact: compactLayout,
                                  onConfigure: () => _openPage(
                                    page: const WorkoutPlanPage(),
                                    pageState:
                                        const PersistedPageState.workoutPlan(),
                                  ),
                                  onStart: currentWorkout == null
                                      ? null
                                      : _skippingWorkout
                                      ? null
                                      : () => _startWorkout(currentWorkout!),
                                  onSkip: canSkipWorkout && !_skippingWorkout
                                      ? () => _skipWorkout(currentWorkout!)
                                      : null,
                                ),
                                SizedBox(height: verticalGap),
                                _MetricsStrip(
                                  sessionsCount: sessions.length,
                                  expectedDays: expectedDays,
                                  attendanceRate: attendanceRate,
                                  compact: compactLayout,
                                ),
                                SizedBox(height: verticalGap),
                                Expanded(
                                  child: AttendanceCalendar(
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
                                    compact: compactLayout,
                                    onMonthChanged: (nextMonth) {
                                      final nextVisibleMonth = _monthAnchor(
                                        nextMonth,
                                      );
                                      final monthChanged =
                                          nextVisibleMonth.year !=
                                              _visibleMonth.year ||
                                          nextVisibleMonth.month !=
                                              _visibleMonth.month;

                                      setState(() {
                                        _visibleMonth = nextVisibleMonth;
                                        if (monthChanged) {
                                          _sessionsStream =
                                              _buildSessionsStream(
                                                nextVisibleMonth,
                                              );
                                        }
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(height: compactLayout ? 6 : 8),
                                _CalendarLegendBar(compact: compactLayout),
                              ],
                            ),
                          );
                        },
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
  final bool compact;
  final VoidCallback onConfigure;
  final VoidCallback? onStart;
  final VoidCallback? onSkip;

  const _TodayWorkoutCard({
    required this.workout,
    required this.trainedToday,
    required this.isSkippingWorkout,
    required this.showSkipAction,
    required this.compact,
    required this.onConfigure,
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final currentWorkout = workout;
    final cardRadius = compact ? 22.0 : 26.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
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
            color: Colors.black.withValues(alpha: compact ? 0.1 : 0.16),
            blurRadius: compact ? 16 : 24,
            offset: Offset(0, compact ? 10 : 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: currentWorkout == null
            ? _EmptyTodayWorkoutContent(
                compact: compact,
                onConfigure: onConfigure,
              )
            : _TodayWorkoutContent(
                workout: currentWorkout,
                trainedToday: trainedToday,
                isSkippingWorkout: isSkippingWorkout,
                showSkipAction: showSkipAction,
                compact: compact,
                onStart: onStart,
                onSkip: onSkip,
              ),
      ),
    );
  }
}

class _EmptyTodayWorkoutContent extends StatelessWidget {
  final bool compact;
  final VoidCallback onConfigure;

  const _EmptyTodayWorkoutContent({
    required this.compact,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return Row(
        children: [
          Expanded(
            child: _TodayWorkoutTextBlock(
              label: 'Treino do dia',
              title: 'Nenhuma sequencia',
              subtitle: 'Configure a ordem semanal para liberar a home.',
              compact: true,
            ),
          ),
          const SizedBox(width: 12),
          _CompactActionButton(
            icon: Icons.calendar_view_week_rounded,
            label: 'Configurar',
            onPressed: onConfigure,
            filled: true,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Treino do dia',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppThemeColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Text('Nenhuma sequencia configurada', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Organize a ordem dos treinos para liberar a recomendacao diaria.',
          style: theme.textTheme.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onConfigure,
          icon: const Icon(Icons.calendar_view_week_rounded),
          label: const Text('Configurar treino semanal'),
        ),
      ],
    );
  }
}

class _TodayWorkoutContent extends StatelessWidget {
  final Workout workout;
  final bool trainedToday;
  final bool isSkippingWorkout;
  final bool showSkipAction;
  final bool compact;
  final VoidCallback? onStart;
  final VoidCallback? onSkip;

  const _TodayWorkoutContent({
    required this.workout,
    required this.trainedToday,
    required this.isSkippingWorkout,
    required this.showSkipAction,
    required this.compact,
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final workoutAreas = workout.description.trim().isEmpty
        ? 'Areas nao definidas'
        : workout.description.trim();

    if (compact) {
      return Row(
        children: [
          Expanded(
            child: _TodayWorkoutTextBlock(
              label: 'Treino do dia',
              title: workoutAreas,
              subtitle: trainedToday ? 'Treino registrado hoje.' : '',
              compact: true,
              trailing: trainedToday
                  ? _StatusPill(
                      label: 'Concluido',
                      backgroundColor: AppThemeColors.primary.withValues(
                        alpha: 0.14,
                      ),
                      textColor: AppThemeColors.primaryStrong,
                      compact: true,
                    )
                  : null,
            ),
          ),
          if (!trainedToday) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: showSkipAction ? 116 : 108,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CompactActionButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'Iniciar',
                    onPressed: onStart,
                    filled: true,
                  ),
                  if (showSkipAction) ...[
                    const SizedBox(height: 6),
                    _CompactActionButton(
                      icon: Icons.skip_next_rounded,
                      label: isSkippingWorkout ? 'Pulando' : 'Pular',
                      onPressed: onSkip,
                      filled: false,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    }

    final theme = Theme.of(context);

    return Column(
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
            if (trainedToday)
              _StatusPill(
                label: 'Concluido',
                backgroundColor: AppThemeColors.primary.withValues(alpha: 0.14),
                textColor: AppThemeColors.primaryStrong,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          workoutAreas,
          style: theme.textTheme.headlineSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),
        if (trainedToday)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemeColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Treino de hoje registrado. Revise os proximos passos da semana.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppThemeColors.primaryStrong,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSkip,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(
                      isSkippingWorkout ? 'Pulando...' : 'Pular treino',
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _TodayWorkoutTextBlock extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;
  final bool compact;
  final Widget? trailing;

  const _TodayWorkoutTextBlock({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.compact,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppThemeColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitleText.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitleText,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? FilledButton.styleFrom(
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            side: const BorderSide(color: AppThemeColors.outlineStrong),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          );
    final child = _ActionButtonLabel(icon: icon, label: label);

    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

class _ActionButtonLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButtonLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool compact;

  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: compact ? 11 : null,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MetricsStrip extends StatelessWidget {
  final int sessionsCount;
  final int expectedDays;
  final int attendanceRate;
  final bool compact;

  const _MetricsStrip({
    required this.sessionsCount,
    required this.expectedDays,
    required this.attendanceRate,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricStripItem(
              label: 'No mes',
              value: '$sessionsCount',
              accent: AppThemeColors.primary,
              compact: compact,
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _MetricStripItem(
              label: 'Meta',
              value: '$expectedDays',
              accent: AppThemeColors.secondary,
              compact: compact,
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _MetricStripItem(
              label: 'Ritmo',
              value: '$attendanceRate%',
              accent: AppThemeColors.warning,
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricStripItem extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool compact;

  const _MetricStripItem({
    required this.label,
    required this.value,
    required this.accent,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: compact ? 7 : 8,
          height: compact ? 7 : 8,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: compact ? 10 : 11,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontSize: compact ? 17 : 19,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppThemeColors.outline,
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

class _CalendarLegendBar extends StatelessWidget {
  final bool compact;

  const _CalendarLegendBar({required this.compact});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 24 : 28,
      child: Row(
        children: [
          Expanded(
            child: _LegendItem(
              color: AppThemeColors.primary,
              label: 'Concluido',
              compact: compact,
            ),
          ),
          Expanded(
            child: _LegendItem(
              color: AppThemeColors.danger,
              label: 'Perdido',
              compact: compact,
            ),
          ),
          Expanded(
            child: _LegendItem(
              color: AppThemeColors.surfaceSoft,
              label: 'Hoje',
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool compact;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: compact ? 8 : 9,
          height: compact ? 8 : 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: compact ? 10 : 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

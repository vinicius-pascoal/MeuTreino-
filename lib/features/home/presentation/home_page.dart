import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../auth/data/auth_service.dart';
import '../../exercises/presentation/exercise_library_page.dart';
import '../../home_widgets/data/app_home_widget_service.dart';
import '../../workout_automation/presentation/auto_workout_page.dart';
import '../../workout_plan/data/workout_plan_service.dart';
import '../../workout_plan/models/workout_plan.dart';
import '../../workout_plan/presentation/workout_plan_page.dart';
import '../../workout_session/data/workout_session_service.dart';
import '../../workout_session/models/workout_session_summary.dart';
import '../../workout_session/presentation/workout_session_page.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/presentation/workouts_page.dart';
import 'widgets/attendance_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  final _workoutService = WorkoutService();
  final _planService = WorkoutPlanService();
  final _sessionService = WorkoutSessionService();
  final _homeWidgetService = AppHomeWidgetService();

  DateTime _focusedDay = DateTime.now();
  String? _lastWidgetPayload;

  Future<void> _logout() async {
    await _authService.logout();
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

  DateTime get _monthStart => DateTime(_focusedDay.year, _focusedDay.month, 1);

  DateTime get _monthEnd =>
      DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

  int _countExpectedDaysInMonth(WorkoutPlan? plan) {
    final currentPlan = plan;
    if (currentPlan == null || currentPlan.trainingWeekDays.isEmpty) {
      return 0;
    }

    var total = 0;
    var cursor = _monthStart;

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
    return StreamBuilder<List<Workout>>(
      stream: _workoutService.watchWorkouts(),
      builder: (context, workoutsSnapshot) {
        final workouts = workoutsSnapshot.data ?? [];

        return StreamBuilder<WorkoutPlan?>(
          stream: _planService.watchPlan(),
          builder: (context, planSnapshot) {
            final plan = planSnapshot.data;
            final currentWorkout = _findCurrentWorkout(
              plan: plan,
              workouts: workouts,
            );

            return StreamBuilder<List<WorkoutSessionSummary>>(
              stream: _sessionService.watchSessionsBetween(
                start: _monthStart,
                end: _monthEnd,
              ),
              builder: (context, sessionsSnapshot) {
                final sessions = sessionsSnapshot.data ?? [];
                final todayKey = DateKey.fromDate(DateTime.now());
                final trainedToday = sessions.any(
                  (session) => session.workoutDateKey == todayKey,
                );
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
                            onConfigure: () =>
                                _openPage(const WorkoutPlanPage()),
                            onStart: currentWorkout == null
                                ? null
                                : () => _startWorkout(currentWorkout),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 520;
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
                                      hint: 'treinos concluidos',
                                      accent: AppThemeColors.primary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _MetricCard(
                                      label: 'Meta',
                                      value: '$expectedDays',
                                      hint: 'dias planejados',
                                      accent: AppThemeColors.secondary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _MetricCard(
                                      label: 'Ritmo',
                                      value: '$attendanceRate%',
                                      hint: 'aderencia atual',
                                      accent: AppThemeColors.warning,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          AttendanceCalendar(
                            focusedDay: _focusedDay,
                            sessions: sessions,
                            plan: plan,
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          const Wrap(
                            spacing: 10,
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
                  bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
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
  final VoidCallback onConfigure;
  final VoidCallback? onStart;

  const _TodayWorkoutCard({
    required this.workout,
    required this.trainedToday,
    required this.onConfigure,
    required this.onStart,
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
                    icon: const Icon(Icons.route_rounded),
                    label: const Text('Configurar sequencia'),
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
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Iniciar treino'),
                      ),
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
  final String hint;
  final Color accent;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.hint,
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
          ),
          const SizedBox(height: 4),
          Text(hint, style: theme.textTheme.bodySmall),
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

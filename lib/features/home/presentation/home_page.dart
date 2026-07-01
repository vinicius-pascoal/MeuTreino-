import 'package:flutter/material.dart';

import '../../../core/utils/date_key.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
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
                  body: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF091524),
                          Color(0xFF07111F),
                          Color(0xFF050B14),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        children: [
                          _HomeTopBar(onLogout: _logout),
                          const SizedBox(height: 18),
                          _TodayWorkoutCard(
                            workout: currentWorkout,
                            trainedToday: trainedToday,
                            onConfigure: () =>
                                _openPage(const WorkoutPlanPage()),
                            onStart: currentWorkout == null
                                ? null
                                : () => _startWorkout(currentWorkout),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  label: 'No mes',
                                  value: '${sessions.length}',
                                  hint: 'treinos',
                                  accent: const Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetricCard(
                                  label: 'Meta',
                                  value: '$expectedDays',
                                  hint: 'dias alvo',
                                  accent: const Color(0xFF38BDF8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetricCard(
                                  label: 'Ritmo',
                                  value: '$attendanceRate%',
                                  hint: 'aderencia',
                                  accent: const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
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
                                color: Color(0xFF22C55E),
                                label: 'Treino concluido',
                              ),
                              _LegendPill(
                                color: Color(0xFFEF4444),
                                label: 'Dia perdido',
                              ),
                              _LegendPill(
                                color: Color(0xFF334155),
                                label: 'Hoje',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MeuTreino+', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: IconButton(
            tooltip: 'Sair',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: currentWorkout == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Treino do dia',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nenhuma sequencia configurada',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Organize a ordem dos treinos para liberar a recomendacao diaria.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
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
                      const Expanded(
                        child: Text(
                          'Treino do dia',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: trainedToday
                              ? const Color(0xFF22C55E).withValues(alpha: 0.18)
                              : const Color(0xFF38BDF8).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          trainedToday ? 'Concluido' : 'Pronto',
                          style: TextStyle(
                            color: trainedToday
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF7DD3FC),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentWorkout.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  if (currentWorkout.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      currentWorkout.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (trainedToday)
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Treino de hoje registrado. Aproveite o app para planejar o proximo passo.',
                            style: TextStyle(
                              color: Color(0xFF86EFAC),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(hint, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white70)),
      ],
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
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

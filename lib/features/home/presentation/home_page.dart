import 'package:flutter/material.dart';

import '../../../core/utils/date_key.dart';
import '../../auth/data/auth_service.dart';
import '../../exercises/presentation/exercise_library_page.dart';
import '../../history/presentation/history_page.dart';
import '../../progress/presentation/progress_page.dart';
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

  DateTime _focusedDay = DateTime.now();

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

  DateTime get _monthStart {
    return DateTime(_focusedDay.year, _focusedDay.month, 1);
  }

  DateTime get _monthEnd {
    return DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
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

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('MeuTreino+'),
                    actions: [
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    minimum: const EdgeInsets.all(16),
                    child: ListView(
                      children: [
                        const Text(
                          'Seu progresso na academia, série por série.',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TodayWorkoutCard(
                          workout: currentWorkout,
                          trainedToday: trainedToday,
                          onConfigure: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WorkoutPlanPage(),
                              ),
                            );
                          },
                          onStart: currentWorkout == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WorkoutSessionPage(
                                        workout: currentWorkout,
                                      ),
                                    ),
                                  );
                                },
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            _LegendDot(color: Color(0xFF22C55E), label: 'Foi'),
                            SizedBox(width: 12),
                            _LegendDot(
                              color: Color(0xFFEF4444),
                              label: 'Faltou',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _HomeCard(
                          title: 'Meus treinos',
                          subtitle: 'Crie, edite e organize seus treinos.',
                          icon: Icons.calendar_month,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WorkoutsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _HomeCard(
                          title: 'Configurar sequência ABC',
                          subtitle:
                              'Escolha a ordem dos treinos e dias esperados.',
                          icon: Icons.route,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WorkoutPlanPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _HomeCard(
                          title: 'Biblioteca de exercícios',
                          subtitle: 'Veja exercícios com fotos locais.',
                          icon: Icons.photo_library,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ExerciseLibraryPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _HomeCard(
                          title: 'Histórico',
                          subtitle: 'Veja treinos realizados e séries salvas.',
                          icon: Icons.history,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const HistoryPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _HomeCard(
                          title: 'Progresso',
                          subtitle: 'Volume, frequência e evolução.',
                          icon: Icons.show_chart,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProgressPage(),
                              ),
                            );
                          },
                        ),
                      ],
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

    if (currentWorkout == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Treino do dia',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nenhuma sequência configurada',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onConfigure,
                icon: const Icon(Icons.route),
                label: const Text('Configurar ABC'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Treino do dia',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              currentWorkout.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            if (currentWorkout.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(currentWorkout.description),
            ],
            const SizedBox(height: 12),
            if (trainedToday)
              const Text(
                'Você já treinou hoje.',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar treino'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF22C55E),
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

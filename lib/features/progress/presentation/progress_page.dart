import 'package:flutter/material.dart';

import '../../workout_session/data/workout_session_service.dart';
import '../../workout_session/models/workout_session_summary.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = WorkoutSessionService();

    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: StreamBuilder<List<WorkoutSessionSummary>>(
        stream: service.watchRecentSessions(limit: 100),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data!;

          final totalWorkouts = sessions.length;
          final totalVolume = sessions.fold<double>(
            0,
            (sum, item) => sum + item.totalVolume,
          );
          final totalSets = sessions.fold<int>(
            0,
            (sum, item) => sum + item.totalSets,
          );

          final averageVolume = totalWorkouts == 0
              ? 0
              : totalVolume / totalWorkouts;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProgressCard(
                title: 'Treinos realizados',
                value: '$totalWorkouts',
                icon: Icons.fitness_center,
              ),
              const SizedBox(height: 12),
              _ProgressCard(
                title: 'Volume total',
                value: '${totalVolume.toStringAsFixed(0)} kg',
                icon: Icons.monitor_weight,
              ),
              const SizedBox(height: 12),
              _ProgressCard(
                title: 'Séries realizadas',
                value: '$totalSets',
                icon: Icons.format_list_numbered,
              ),
              const SizedBox(height: 12),
              _ProgressCard(
                title: 'Volume médio por treino',
                value: '${averageVolume.toStringAsFixed(0)} kg',
                icon: Icons.show_chart,
              ),
              const SizedBox(height: 20),
              const Text(
                'Últimos treinos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...sessions
                  .take(10)
                  .map(
                    (session) => Card(
                      child: ListTile(
                        title: Text(session.workoutName),
                        subtitle: Text(
                          '${session.totalSets} séries • ${session.totalVolume.toStringAsFixed(0)} kg',
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ProgressCard({
    required this.title,
    required this.value,
    required this.icon,
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
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

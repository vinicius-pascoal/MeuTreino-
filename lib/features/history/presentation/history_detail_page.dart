import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../workout_session/data/workout_session_service.dart';
import '../../workout_session/models/performed_set.dart';
import '../../workout_session/models/workout_session_summary.dart';

class HistoryDetailPage extends StatelessWidget {
  final WorkoutSessionSummary session;

  const HistoryDetailPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final service = WorkoutSessionService();

    final date = session.finishedAt == null
        ? '-'
        : DateFormat('dd/MM/yyyy HH:mm').format(session.finishedAt!);

    return Scaffold(
      appBar: AppBar(title: Text(session.workoutName)),
      body: StreamBuilder<List<PerformedSet>>(
        stream: service.watchSessionSets(sessionId: session.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sets = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.workoutName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Data: $date'),
                      Text('Séries: ${session.totalSets}'),
                      Text(
                        'Volume total: ${session.totalVolume.toStringAsFixed(0)} kg',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...sets.map(
                (set) => Card(
                  child: ListTile(
                    title: Text(set.exerciseName),
                    subtitle: Text(
                      '${set.muscleGroup} • Série ${set.setNumber}',
                    ),
                    trailing: Text(
                      '${set.weight.toStringAsFixed(1)} kg x ${set.reps}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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

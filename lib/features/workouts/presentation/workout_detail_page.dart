import 'package:flutter/material.dart';

import '../../../core/widgets/exercise_image.dart';
import '../../exercises/presentation/select_exercise_page.dart';
import '../../workout_session/presentation/workout_session_page.dart';
import '../data/workout_service.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';

class WorkoutDetailPage extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final service = WorkoutService();

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        actions: [
          IconButton(
            tooltip: 'Adicionar exercício',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SelectExercisePage(
                    workoutId: workout.id,
                    nextOrder: DateTime.now().millisecondsSinceEpoch,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutSessionPage(workout: workout),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar treino'),
      ),
      body: StreamBuilder<List<WorkoutExercise>>(
        stream: service.watchWorkoutExercises(workoutId: workout.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = snapshot.data!;

          if (exercises.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum exercício neste treino.\nClique no + para adicionar.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final exercise = exercises[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExerciseImage(imageAsset: exercise.imageAsset, height: 170),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${exercise.muscleGroup} • ${exercise.sets} séries • ${exercise.targetReps} reps • ${exercise.restSeconds}s descanso',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

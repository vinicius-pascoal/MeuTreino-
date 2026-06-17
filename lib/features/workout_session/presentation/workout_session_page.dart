import 'package:flutter/material.dart';

import '../../../core/widgets/exercise_image.dart';
import '../../../core/widgets/rest_timer.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/models/workout_exercise.dart';

class WorkoutSessionPage extends StatefulWidget {
  final Workout workout;

  const WorkoutSessionPage({super.key, required this.workout});

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  final _service = WorkoutService();

  int _currentExerciseIndex = 0;
  int _currentSet = 1;

  void _nextSet(WorkoutExercise exercise) {
    if (_currentSet < exercise.sets) {
      setState(() {
        _currentSet++;
      });
      return;
    }

    setState(() {
      _currentSet = 1;
      _currentExerciseIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutExercise>>(
      stream: _service.watchWorkoutExercises(workoutId: widget.workout.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final exercises = snapshot.data!;

        if (exercises.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Treino')),
            body: const Center(
              child: Text('Este treino não possui exercícios.'),
            ),
          );
        }

        if (_currentExerciseIndex >= exercises.length) {
          return Scaffold(
            appBar: AppBar(title: const Text('Treino finalizado')),
            body: SafeArea(
              minimum: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 72,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Treino concluído!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.workout.name,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final exercise = exercises[_currentExerciseIndex];

        return Scaffold(
          appBar: AppBar(title: Text(widget.workout.name)),
          body: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ExerciseImage(imageAsset: exercise.imageAsset, height: 220),
                const SizedBox(height: 18),
                Text(
                  'Exercício ${_currentExerciseIndex + 1} de ${exercises.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${exercise.muscleGroup} • Série $_currentSet de ${exercise.sets}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Carga usada',
                    hintText: '${exercise.currentWeight} kg',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Repetições feitas',
                    hintText: exercise.targetReps,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _nextSet(exercise),
                  icon: const Icon(Icons.check),
                  label: const Text('Concluir série'),
                ),
                const SizedBox(height: 18),
                RestTimer(initialSeconds: exercise.restSeconds),
              ],
            ),
          ),
        );
      },
    );
  }
}

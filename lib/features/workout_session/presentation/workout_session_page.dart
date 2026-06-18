import 'package:flutter/material.dart';

import '../../../core/widgets/exercise_image.dart';
import '../../../core/widgets/rest_timer.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/models/workout_exercise.dart';
import '../data/workout_session_service.dart';
import '../models/completed_set_input.dart';

class WorkoutSessionPage extends StatefulWidget {
  final Workout workout;

  const WorkoutSessionPage({super.key, required this.workout});

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  final _workoutService = WorkoutService();
  final _sessionService = WorkoutSessionService();

  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  final List<CompletedSetInput> _completedSets = [];

  late final DateTime _startedAt;

  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _prepareFields(WorkoutExercise exercise) {
    if (_weightController.text.isEmpty && exercise.currentWeight > 0) {
      _weightController.text = exercise.currentWeight.toStringAsFixed(0);
    }
  }

  Future<void> _completeSet(WorkoutExercise exercise) async {
    final weight =
        double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ??
        0;

    final reps = int.tryParse(_repsController.text.trim()) ?? 0;

    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe as repetições realizadas.')),
      );
      return;
    }

    _completedSets.add(
      CompletedSetInput(
        exercise: exercise,
        setNumber: _currentSet,
        weight: weight,
        reps: reps,
      ),
    );

    _repsController.clear();

    if (_currentSet < exercise.sets) {
      setState(() {
        _currentSet++;
      });
      return;
    }

    setState(() {
      _currentSet = 1;
      _currentExerciseIndex++;
      _weightController.clear();
      _repsController.clear();
    });
  }

  Future<void> _finishWorkout() async {
    setState(() => _saving = true);

    try {
      await _sessionService.finishWorkoutSession(
        workout: widget.workout,
        startedAt: _startedAt,
        completedSets: _completedSets,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino salvo com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar treino: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutExercise>>(
      stream: _workoutService.watchWorkoutExercises(
        workoutId: widget.workout.id,
      ),
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
            appBar: AppBar(title: const Text('Finalizar treino')),
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
                      '${_completedSets.length} séries registradas',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _finishWorkout,
                        icon: const Icon(Icons.save),
                        label: _saving
                            ? const Text('Salvando...')
                            : const Text('Salvar treino'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final exercise = exercises[_currentExerciseIndex];
        _prepareFields(exercise);

        final totalVolume = _completedSets.fold<double>(
          0,
          (sum, item) => sum + item.volume,
        );

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
                const SizedBox(height: 8),
                Text(
                  'Última carga: ${exercise.currentWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Carga usada',
                    suffixText: 'kg',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _repsController,
                  decoration: InputDecoration(
                    labelText: 'Repetições feitas',
                    hintText: exercise.targetReps,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _completeSet(exercise),
                  icon: const Icon(Icons.check),
                  label: const Text('Concluir série'),
                ),
                const SizedBox(height: 18),
                RestTimer(initialSeconds: exercise.restSeconds),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Volume registrado até agora: ${totalVolume.toStringAsFixed(0)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

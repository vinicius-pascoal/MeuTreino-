import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_navigation_state_service.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/exercise_image.dart';
import '../../exercise_stats/data/user_exercise_stats_service.dart';
import '../../exercises/data/exercise_library_service.dart';
import '../../exercises/models/exercise.dart';
import '../../exercises/presentation/select_exercise_page.dart';
import '../../workout_session/presentation/workout_session_page.dart';
import '../data/workout_service.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';

class WorkoutDetailPage extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  Future<void> _editExerciseDialog({
    required BuildContext context,
    required WorkoutExercise exercise,
  }) async {
    final service = WorkoutService();

    final setsController = TextEditingController(text: '${exercise.sets}');
    final repsController = TextEditingController(text: exercise.targetReps);
    final restController = TextEditingController(
      text: '${exercise.restSeconds}',
    );
    final weightController = TextEditingController(
      text: exercise.currentWeight.toStringAsFixed(1),
    );
    final notesController = TextEditingController(text: exercise.notes);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(exercise.name),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: setsController,
                  decoration: const InputDecoration(labelText: 'Series'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: repsController,
                  decoration: const InputDecoration(labelText: 'Repeticoes'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: restController,
                  decoration: const InputDecoration(
                    labelText: 'Descanso em segundos',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (!exercise.isBodyweight) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: 'Carga atual'),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Observacoes'),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                await service.updateWorkoutExercise(
                  workoutId: workout.id,
                  workoutExerciseId: exercise.id,
                  sets: int.tryParse(setsController.text) ?? exercise.sets,
                  targetReps: repsController.text,
                  restSeconds:
                      int.tryParse(restController.text) ?? exercise.restSeconds,
                  currentWeight: exercise.isBodyweight
                      ? 0
                      : double.tryParse(
                              weightController.text.replaceAll(',', '.'),
                            ) ??
                            exercise.currentWeight,
                  notes: notesController.text,
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    setsController.dispose();
    repsController.dispose();
    restController.dispose();
    weightController.dispose();
    notesController.dispose();
  }

  Future<void> _replaceExercise({
    required BuildContext context,
    required WorkoutExercise exercise,
  }) async {
    final workoutService = WorkoutService();
    final libraryService = ExerciseLibraryService();
    final exerciseStatsService = UserExerciseStatsService();

    try {
      final libraryExercises = await libraryService.getExercisesOnce();
      final replacementOptions = _buildReplacementOptions(
        currentExercise: exercise,
        libraryExercises: libraryExercises,
      );

      if (!context.mounted) return;

      if (replacementOptions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nao encontrei exercicios da mesma area para trocar.'),
          ),
        );
        return;
      }

      final replacement = await showModalBottomSheet<Exercise>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return SafeArea(
            child: SizedBox(
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trocar ${exercise.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Escolha um exercicio da mesma area muscular.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: replacementOptions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = replacementOptions[index];
                        final sameRegion =
                            _normalize(item.muscleRegion) ==
                            _normalize(exercise.muscleRegion);

                        return Card(
                          child: ListTile(
                            onTap: () => Navigator.of(sheetContext).pop(item),
                            leading: Icon(
                              sameRegion
                                  ? Icons.check_circle
                                  : Icons.swap_horiz_rounded,
                              color: sameRegion
                                  ? const Color(0xFF22C55E)
                                  : Colors.white70,
                            ),
                            title: Text(item.name),
                            subtitle: Text(_replacementSubtitle(item)),
                            trailing: sameRegion
                                ? const Text(
                                    'Mais proximo',
                                    style: TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (replacement == null) {
        return;
      }

      final replacementWeight =
          replacement.isBodyweight
          ? 0.0
          : await exerciseStatsService.getLastUsedWeight(
                  exerciseLibraryId: replacement.id,
                ) ??
                exercise.currentWeight;

      await workoutService.replaceWorkoutExercise(
        workoutId: workout.id,
        workoutExerciseId: exercise.id,
        exercise: replacement,
        currentWeight: replacementWeight,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Exercicio trocado. Revise a carga e observacoes se necessario.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao trocar exercicio: $error')),
      );
    }
  }

  List<Exercise> _buildReplacementOptions({
    required WorkoutExercise currentExercise,
    required List<Exercise> libraryExercises,
  }) {
    final currentGroup = _normalize(currentExercise.muscleGroup);
    final currentRegion = _normalize(currentExercise.muscleRegion);
    final currentPattern = _normalize(currentExercise.movementPattern);

    final options = libraryExercises.where((candidate) {
      if (candidate.id == currentExercise.exerciseLibraryId) {
        return false;
      }

      return _normalize(candidate.muscleGroup) == currentGroup;
    }).toList();

    options.sort((a, b) {
      final regionCompare = _matchPriority(
        valueA: a.muscleRegion,
        valueB: b.muscleRegion,
        target: currentRegion,
      );
      if (regionCompare != 0) {
        return regionCompare;
      }

      final patternCompare = _matchPriority(
        valueA: a.movementPattern,
        valueB: b.movementPattern,
        target: currentPattern,
      );
      if (patternCompare != 0) {
        return patternCompare;
      }

      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.name.compareTo(b.name);
    });

    return options;
  }

  int _matchPriority({
    required String valueA,
    required String valueB,
    required String target,
  }) {
    final aScore = _normalize(valueA) == target ? 0 : 1;
    final bScore = _normalize(valueB) == target ? 0 : 1;
    return aScore.compareTo(bScore);
  }

  String _replacementSubtitle(Exercise exercise) {
    final parts = <String>[exercise.muscleGroup];

    if (exercise.muscleRegion.trim().isNotEmpty) {
      parts.add(exercise.muscleRegion.trim());
    }

    if (exercise.equipment.trim().isNotEmpty) {
      parts.add(exercise.equipment.trim());
    }

    return parts.join(' - ');
  }

  Future<void> _deleteExercise({
    required BuildContext context,
    required WorkoutExercise exercise,
  }) async {
    final service = WorkoutService();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir exercicio'),
          content: Text('Deseja excluir "${exercise.name}" deste treino?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await service.deleteWorkoutExercise(
        workoutId: workout.id,
        workoutExerciseId: exercise.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = WorkoutService();
    final navigationStateService = AppNavigationStateService();

    return AppPageScaffold(
      title: workout.name,
      currentIndex: 1,
      actions: [
        IconButton(
          tooltip: 'Adicionar exercicio',
          onPressed: () {
            final nextOrder = DateTime.now().millisecondsSinceEpoch;

            unawaited(
              navigationStateService.pushTrackedPage(
                context: context,
                pageState: PersistedPageState.selectExercise(
                  workoutId: workout.id,
                  nextOrder: nextOrder,
                ),
                builder: (_) => SelectExercisePage(
                  workoutId: workout.id,
                  nextOrder: nextOrder,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          unawaited(
            navigationStateService.pushTrackedPage(
              context: context,
              pageState: PersistedPageState.workoutSession(
                workoutId: workout.id,
              ),
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
                'Nenhum exercicio neste treino.\nClique no + para adicionar.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'replace') {
                                    _replaceExercise(
                                      context: context,
                                      exercise: exercise,
                                    );
                                  }

                                  if (value == 'edit') {
                                    _editExerciseDialog(
                                      context: context,
                                      exercise: exercise,
                                    );
                                  }

                                  if (value == 'delete') {
                                    _deleteExercise(
                                      context: context,
                                      exercise: exercise,
                                    );
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'replace',
                                    child: Text('Trocar por similar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Excluir'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _exerciseSubtitle(exercise),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exercise.sets} series - ${exercise.targetReps} reps - ${exercise.restSeconds}s descanso',
                          ),
                          if (!exercise.isBodyweight) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Ultima carga: ${exercise.currentWeight.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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

  String _exerciseSubtitle(WorkoutExercise exercise) {
    final parts = <String>[exercise.muscleGroup];

    if (exercise.muscleRegion.trim().isNotEmpty) {
      parts.add(exercise.muscleRegion.trim());
    }

    if (exercise.equipment.trim().isNotEmpty) {
      parts.add(exercise.equipment.trim());
    }

    return parts.join(' - ');
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

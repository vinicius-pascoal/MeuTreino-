import 'dart:math';

import '../../exercises/data/exercise_library_service.dart';
import '../../exercises/models/exercise.dart';
import '../../workouts/data/workout_service.dart';

class WorkoutAutomationService {
  WorkoutAutomationService({
    ExerciseLibraryService? exerciseLibraryService,
    WorkoutService? workoutService,
  }) : _exerciseLibraryService =
           exerciseLibraryService ?? ExerciseLibraryService(),
       _workoutService = workoutService ?? WorkoutService();

  final ExerciseLibraryService _exerciseLibraryService;
  final WorkoutService _workoutService;

  Future<String> generateWorkout({
    required String name,
    required String description,
    required List<String> muscleGroups,
    required int exercisesPerGroup,
    required int sets,
    required String targetReps,
    required int restSeconds,
    required double currentWeight,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('Informe o nome do treino.');
    }

    if (muscleGroups.isEmpty) {
      throw Exception('Selecione pelo menos um grupo muscular.');
    }

    if (exercisesPerGroup <= 0) {
      throw Exception(
        'A quantidade de exercícios por grupo deve ser maior que zero.',
      );
    }

    if (sets <= 0) {
      throw Exception('A quantidade de séries deve ser maior que zero.');
    }

    if (targetReps.trim().isEmpty) {
      throw Exception('Informe a faixa de repetições.');
    }

    if (restSeconds <= 0) {
      throw Exception('O descanso deve ser maior que zero.');
    }

    final libraryExercises = await _exerciseLibraryService.getExercisesOnce();

    if (libraryExercises.isEmpty) {
      throw Exception(
        'A biblioteca de exercícios está vazia. Popule a biblioteca antes de gerar um treino.',
      );
    }

    final selectedExercises = _selectExercisesByMuscleGroups(
      allExercises: libraryExercises,
      muscleGroups: muscleGroups,
      exercisesPerGroup: exercisesPerGroup,
    );

    if (selectedExercises.isEmpty) {
      throw Exception(
        'Nenhum exercício foi encontrado para os grupos selecionados.',
      );
    }

    final workoutId = await _workoutService.createWorkoutReturningId(
      name: name,
      description: description,
      weekDays: [],
    );

    await _workoutService.addExercisesToWorkoutBatch(
      workoutId: workoutId,
      exercises: selectedExercises,
      sets: sets,
      targetReps: targetReps,
      restSeconds: restSeconds,
      currentWeight: currentWeight,
    );

    return workoutId;
  }

  List<Exercise> _selectExercisesByMuscleGroups({
    required List<Exercise> allExercises,
    required List<String> muscleGroups,
    required int exercisesPerGroup,
  }) {
    final random = Random();
    final selected = <Exercise>[];

    for (final group in muscleGroups) {
      final groupExercises = allExercises
          .where(
            (exercise) =>
                exercise.muscleGroup.trim().toLowerCase() ==
                group.trim().toLowerCase(),
          )
          .toList();

      groupExercises.shuffle(random);

      selected.addAll(groupExercises.take(exercisesPerGroup));
    }

    return selected;
  }
}

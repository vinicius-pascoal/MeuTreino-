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
    required Map<String, int> exercisesPerGroup,
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

    for (final group in muscleGroups) {
      final quantity = exercisesPerGroup[group] ?? 0;
      if (quantity <= 0) {
        throw Exception(
          'Defina uma quantidade válida de exercícios para $group.',
        );
      }
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

    final selectedExercises = _selectBalancedExercisesByMuscleGroups(
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

  List<Exercise> _selectBalancedExercisesByMuscleGroups({
    required List<Exercise> allExercises,
    required List<String> muscleGroups,
    required Map<String, int> exercisesPerGroup,
  }) {
    final selected = <Exercise>[];
    final normalizedGroupOrder = <String, int>{};

    for (int index = 0; index < muscleGroups.length; index++) {
      normalizedGroupOrder[_normalize(muscleGroups[index])] = index;
    }

    for (final group in muscleGroups) {
      final groupExercises = allExercises
          .where(
            (exercise) => _normalize(exercise.muscleGroup) == _normalize(group),
          )
          .toList()
        ..sort(_baseExerciseCompare);

      if (groupExercises.isEmpty) {
        continue;
      }

      selected.addAll(
        _pickExercisesForGroup(
          groupExercises: groupExercises,
          exercisesPerGroup: exercisesPerGroup[group] ?? 0,
        ),
      );
    }

    selected.sort((a, b) {
      final aAbdomen = _isAbdomen(a);
      final bAbdomen = _isAbdomen(b);

      if (aAbdomen != bAbdomen) {
        return aAbdomen ? 1 : -1;
      }

      final groupCompare =
          (normalizedGroupOrder[_normalize(a.muscleGroup)] ?? 999)
              .compareTo(normalizedGroupOrder[_normalize(b.muscleGroup)] ?? 999);
      if (groupCompare != 0) {
        return groupCompare;
      }

      final compoundCompare = _compoundPriority(a).compareTo(
        _compoundPriority(b),
      );
      if (compoundCompare != 0) {
        return compoundCompare;
      }

      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.name.compareTo(b.name);
    });

    return selected;
  }

  List<Exercise> _pickExercisesForGroup({
    required List<Exercise> groupExercises,
    required int exercisesPerGroup,
  }) {
    final selected = <Exercise>[];
    final usedIds = <String>{};
    final regionCounts = <String, int>{};
    final movementCounts = <String, int>{};
    final equipmentCounts = <String, int>{};

    while (selected.length < exercisesPerGroup) {
      final remaining = groupExercises
          .where((exercise) => !usedIds.contains(exercise.id))
          .toList();

      if (remaining.isEmpty) {
        break;
      }

      remaining.sort(
        (a, b) => _selectionScore(
          exercise: a,
          regionCounts: regionCounts,
          movementCounts: movementCounts,
          equipmentCounts: equipmentCounts,
        ).compareTo(
          _selectionScore(
            exercise: b,
            regionCounts: regionCounts,
            movementCounts: movementCounts,
            equipmentCounts: equipmentCounts,
          ),
        ),
      );

      final next = remaining.first;
      selected.add(next);
      usedIds.add(next.id);
      _increment(regionCounts, next.muscleRegion);
      _increment(movementCounts, next.movementPattern);
      _increment(equipmentCounts, next.equipment);
    }

    return selected;
  }

  int _selectionScore({
    required Exercise exercise,
    required Map<String, int> regionCounts,
    required Map<String, int> movementCounts,
    required Map<String, int> equipmentCounts,
  }) {
    final regionCount = _countFor(regionCounts, exercise.muscleRegion);
    final movementCount = _countFor(movementCounts, exercise.movementPattern);
    final equipmentCount = _countFor(equipmentCounts, exercise.equipment);

    return (exercise.isCompound ? 0 : 1000) +
        (exercise.priority * 100) +
        (regionCount * 40) +
        (movementCount * 20) +
        (equipmentCount * 8) +
        _baseExerciseTieBreaker(exercise);
  }

  int _baseExerciseCompare(Exercise a, Exercise b) {
    final compoundCompare = _compoundPriority(a).compareTo(
      _compoundPriority(b),
    );
    if (compoundCompare != 0) {
      return compoundCompare;
    }

    final priorityCompare = a.priority.compareTo(b.priority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }

    final regionCompare = a.muscleRegion.compareTo(b.muscleRegion);
    if (regionCompare != 0) {
      return regionCompare;
    }

    return a.name.compareTo(b.name);
  }

  int _baseExerciseTieBreaker(Exercise exercise) {
    return exercise.name.codeUnits.fold(0, (sum, char) => sum + char);
  }

  int _compoundPriority(Exercise exercise) => exercise.isCompound ? 0 : 1;

  bool _isAbdomen(Exercise exercise) {
    return _normalize(exercise.muscleGroup) == _normalize('Abdomen');
  }

  int _countFor(Map<String, int> counts, String value) {
    final key = _normalize(value);
    if (key.isEmpty) {
      return 0;
    }

    return counts[key] ?? 0;
  }

  void _increment(Map<String, int> counts, String value) {
    final key = _normalize(value);
    if (key.isEmpty) {
      return;
    }

    counts[key] = (counts[key] ?? 0) + 1;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[\u00e1\u00e0\u00e2\u00e3\u00e4]'), 'a')
        .replaceAll(RegExp('[\u00e9\u00e8\u00ea\u00eb]'), 'e')
        .replaceAll(RegExp('[\u00ed\u00ec\u00ee\u00ef]'), 'i')
        .replaceAll(RegExp('[\u00f3\u00f2\u00f4\u00f5\u00f6]'), 'o')
        .replaceAll(RegExp('[\u00fa\u00f9\u00fb\u00fc]'), 'u')
        .replaceAll('\u00e7', 'c');
  }
}

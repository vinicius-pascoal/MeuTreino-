import '../../workouts/models/workout_exercise.dart';

class CompletedSetInput {
  final WorkoutExercise exercise;
  final int setNumber;
  final double weight;
  final int reps;

  CompletedSetInput({
    required this.exercise,
    required this.setNumber,
    required this.weight,
    required this.reps,
  });

  double get volume => weight * reps;
}

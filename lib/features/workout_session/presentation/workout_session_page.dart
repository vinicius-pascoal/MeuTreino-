import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/rest_timer_value.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/exercise_image.dart';
import '../../../core/widgets/rest_timer.dart';
import '../../home_widgets/data/app_home_widget_service.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/models/workout_exercise.dart';
import '../data/workout_session_draft_service.dart';
import '../data/workout_session_service.dart';
import '../models/completed_set_input.dart';

const _sessionAccentColor = Color(0xFF22C55E);
const _sessionAccentDarkColor = Color(0xFF052E16);
const _sessionPanelColor = Color(0xFF162033);
const _sessionPanelBorderColor = Color(0xFF243041);
const _sessionInputColor = Color(0xFF101827);

class WorkoutSessionPage extends StatefulWidget {
  final Workout workout;

  const WorkoutSessionPage({super.key, required this.workout});

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

typedef _CompletedSetsFor = int Function(String exerciseId);
typedef _ExerciseCompletionResolver = bool Function(WorkoutExercise exercise);

class _CompactWorkoutSessionScaffold extends StatelessWidget {
  final String workoutName;
  final List<WorkoutExercise> exercises;
  final WorkoutExercise selectedExercise;
  final String subtitle;
  final int currentSet;
  final int completedExercises;
  final int completedSets;
  final int selectedCompletedSets;
  final double totalVolume;
  final _CompletedSetsFor completedSetsFor;
  final _ExerciseCompletionResolver isExerciseCompleted;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final RestTimerValue? restTimerValue;
  final ValueChanged<WorkoutExercise> onExerciseSelected;
  final ValueChanged<RestTimerValue> onRestTimerChanged;
  final VoidCallback? onCompleteSet;

  const _CompactWorkoutSessionScaffold({
    required this.workoutName,
    required this.exercises,
    required this.selectedExercise,
    required this.subtitle,
    required this.currentSet,
    required this.completedExercises,
    required this.completedSets,
    required this.selectedCompletedSets,
    required this.totalVolume,
    required this.completedSetsFor,
    required this.isExerciseCompleted,
    required this.weightController,
    required this.repsController,
    required this.restTimerValue,
    required this.onExerciseSelected,
    required this.onRestTimerChanged,
    required this.onCompleteSet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workoutName)),
      body: AppBackground(
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxHeight < 690 || constraints.maxWidth < 360;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SessionSummaryStrip(
                    completedExercises: completedExercises,
                    totalExercises: exercises.length,
                    completedSets: completedSets,
                    totalVolume: totalVolume,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  SizedBox(
                    height: compact ? 76 : 88,
                    child: _ExerciseSelectorStrip(
                      exercises: exercises,
                      selectedExercise: selectedExercise,
                      completedSetsFor: completedSetsFor,
                      isExerciseCompleted: isExerciseCompleted,
                      onSelected: onExerciseSelected,
                      compact: compact,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Expanded(
                    child: _ActiveExercisePanel(
                      exercise: selectedExercise,
                      subtitle: subtitle,
                      currentSet: currentSet,
                      completedSets: selectedCompletedSets,
                      compact: compact,
                      weightController: weightController,
                      repsController: repsController,
                      isCompleted: isExerciseCompleted(selectedExercise),
                      restTimerValue: restTimerValue,
                      onRestTimerChanged: onRestTimerChanged,
                      onCompleteSet: onCompleteSet,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SessionSummaryStrip extends StatelessWidget {
  final int completedExercises;
  final int totalExercises;
  final int completedSets;
  final double totalVolume;
  final bool compact;

  const _SessionSummaryStrip({
    required this.completedExercises,
    required this.totalExercises,
    required this.completedSets,
    required this.totalVolume,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseProgress = totalExercises == 0
        ? 0.0
        : completedExercises / totalExercises;

    return Container(
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, compact ? 8 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B2940).withValues(alpha: 0.94),
            const Color(0xFF101827).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  icon: Icons.fitness_center_rounded,
                  label: 'Exercicios',
                  value: '$completedExercises/$totalExercises',
                  compact: compact,
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  icon: Icons.checklist_rounded,
                  label: 'Series',
                  value: '$completedSets',
                  compact: compact,
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Volume',
                  value: '${totalVolume.toStringAsFixed(0)} kg',
                  compact: compact,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 7 : 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: exerciseProgress.clamp(0.0, 1.0).toDouble(),
              minHeight: compact ? 5 : 6,
              backgroundColor: const Color(0xFF0F172A),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _sessionAccentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  const _SummaryValue({
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: compact ? 12 : 13),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: compact ? 10 : 11,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 14 : 16,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ExerciseSelectorStrip extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final WorkoutExercise selectedExercise;
  final _CompletedSetsFor completedSetsFor;
  final _ExerciseCompletionResolver isExerciseCompleted;
  final ValueChanged<WorkoutExercise> onSelected;
  final bool compact;

  const _ExerciseSelectorStrip({
    required this.exercises,
    required this.selectedExercise,
    required this.completedSetsFor,
    required this.isExerciseCompleted,
    required this.onSelected,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final selected = exercise.id == selectedExercise.id;
        final completed = isExerciseCompleted(exercise);

        return _ExerciseSelectorChip(
          index: index + 1,
          exercise: exercise,
          selected: selected,
          completed: completed,
          completedSets: completedSetsFor(exercise.id),
          compact: compact,
          onTap: () => onSelected(exercise),
        );
      },
    );
  }
}

class _ExerciseSelectorChip extends StatelessWidget {
  final int index;
  final WorkoutExercise exercise;
  final bool selected;
  final bool completed;
  final int completedSets;
  final bool compact;
  final VoidCallback onTap;

  const _ExerciseSelectorChip({
    required this.index,
    required this.exercise,
    required this.selected,
    required this.completed,
    required this.completedSets,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = exercise.sets <= 0
        ? 0.0
        : (completedSets / exercise.sets).clamp(0.0, 1.0).toDouble();
    final thumbnailSize = compact ? 50.0 : 58.0;
    final muscleLabel = exercise.muscleRegion.trim().isNotEmpty
        ? exercise.muscleRegion.trim()
        : exercise.muscleGroup.trim();

    return SizedBox(
      width: compact ? 178 : 208,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: selected ? 1 : 0.97,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(compact ? 8 : 9),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _sessionAccentColor.withValues(alpha: 0.22),
                        const Color(0xFF1E293B).withValues(alpha: 0.98),
                      ],
                    )
                  : null,
              color: selected ? null : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected || completed
                    ? _sessionAccentColor.withValues(
                        alpha: selected ? 0.9 : 0.55,
                      )
                    : _sessionPanelBorderColor,
                width: selected ? 1.4 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _sessionAccentColor.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? _sessionAccentColor.withValues(alpha: 0.65)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: ExerciseImage(
                        imageAsset: exercise.imageAsset,
                        width: thumbnailSize,
                        height: thumbnailSize,
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    Positioned(
                      right: -5,
                      top: -5,
                      child: _MiniExerciseStatusBadge(
                        index: index,
                        selected: selected,
                        completed: completed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 12 : 14,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        muscleLabel.isEmpty ? 'Exercicio' : muscleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: compact ? 10 : 11,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: const Color(0xFF0F172A),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  selected
                                      ? _sessionAccentColor
                                      : _sessionAccentColor.withValues(
                                          alpha: 0.72,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '$completedSets/${exercise.sets}',
                            style: TextStyle(
                              color: completed
                                  ? _sessionAccentColor
                                  : Colors.white70,
                              fontSize: compact ? 10 : 11,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniExerciseStatusBadge extends StatelessWidget {
  final int index;
  final bool selected;
  final bool completed;

  const _MiniExerciseStatusBadge({
    required this.index,
    required this.selected,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final background = completed
        ? _sessionAccentColor
        : selected
        ? Colors.white
        : _sessionPanelColor;
    final foreground = completed || !selected
        ? Colors.white
        : _sessionAccentDarkColor;

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: _sessionPanelColor, width: 2),
      ),
      child: completed
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : Text(
              '$index',
              style: TextStyle(
                color: foreground,
                fontSize: 10,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _ActiveExercisePanel extends StatelessWidget {
  final WorkoutExercise exercise;
  final String subtitle;
  final int currentSet;
  final int completedSets;
  final bool compact;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final bool isCompleted;
  final RestTimerValue? restTimerValue;
  final ValueChanged<RestTimerValue> onRestTimerChanged;
  final VoidCallback? onCompleteSet;

  const _ActiveExercisePanel({
    required this.exercise,
    required this.subtitle,
    required this.currentSet,
    required this.completedSets,
    required this.compact,
    required this.weightController,
    required this.repsController,
    required this.isCompleted,
    required this.restTimerValue,
    required this.onRestTimerChanged,
    required this.onCompleteSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A263A),
            _sessionPanelColor,
            Color(0xFF0F172A),
          ],
          stops: [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _sessionAccentColor.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: _sessionAccentColor.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tight = constraints.maxHeight < 430;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ExerciseInfoBlock(
                exercise: exercise,
                subtitle: subtitle,
                currentSet: currentSet,
                compact: compact || tight,
              ),
              SizedBox(height: tight ? 8 : 10),
              _SetProgressBar(
                completedSets: completedSets,
                totalSets: exercise.sets,
                compact: compact || tight,
              ),
              if (exercise.notes.trim().isNotEmpty && !tight) ...[
                const SizedBox(height: 8),
                Text(
                  exercise.notes.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
              SizedBox(height: tight ? 8 : 10),
              Expanded(
                child: _ActiveExerciseImage(exercise: exercise),
              ),
              SizedBox(height: tight ? 8 : 10),
              _SetEntryRow(
                exercise: exercise,
                compact: compact || tight,
                weightController: weightController,
                repsController: repsController,
                isCompleted: isCompleted,
                onCompleteSet: onCompleteSet,
              ),
              SizedBox(height: tight ? 8 : 10),
              RestTimer(
                key: ValueKey('${exercise.id}-$completedSets'),
                initialSeconds: exercise.restSeconds,
                initialValue: restTimerValue,
                onChanged: onRestTimerChanged,
                compact: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseInfoBlock extends StatelessWidget {
  final WorkoutExercise exercise;
  final String subtitle;
  final int currentSet;
  final bool compact;

  const _ExerciseInfoBlock({
    required this.exercise,
    required this.subtitle,
    required this.currentSet,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _InfoPill(
              label: 'Serie $currentSet/${exercise.sets}',
              filled: true,
              compact: compact,
            ),
            if (!exercise.isBodyweight) ...[
              const SizedBox(width: 8),
              Flexible(
                child: _InfoPill(
                  label: '${exercise.currentWeight.toStringAsFixed(1)} kg',
                  compact: compact,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          exercise.name,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 20 : 24,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white70,
            fontSize: compact ? 12 : 13,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _InfoPill(label: '${exercise.targetReps} reps', compact: true),
            _InfoPill(label: '${exercise.restSeconds}s descanso', compact: true),
          ],
        ),
      ],
    );
  }
}

class _ActiveExerciseImage extends StatelessWidget {
  final WorkoutExercise exercise;

  const _ActiveExerciseImage({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - 4).clamp(0.0, constraints.maxHeight)
            : 160.0;

        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              ExerciseImage(
                imageAsset: exercise.imageAsset,
                height: imageHeight.toDouble(),
                width: double.infinity,
                borderRadius: BorderRadius.circular(18),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    exercise.muscleGroup.trim().isEmpty
                        ? 'Exercicio atual'
                        : exercise.muscleGroup.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final bool filled;
  final bool compact;

  const _InfoPill({
    required this.label,
    this.filled = false,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: filled
            ? _sessionAccentColor.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled
              ? _sessionAccentColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: filled ? _sessionAccentColor : Colors.white70,
          fontSize: compact ? 11 : 12,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SetProgressBar extends StatelessWidget {
  final int completedSets;
  final int totalSets;
  final bool compact;

  const _SetProgressBar({
    required this.completedSets,
    required this.totalSets,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedTotal = totalSets <= 0 ? 1 : totalSets;

    return Row(
      children: List.generate(normalizedTotal, (index) {
        final completed = index < completedSets;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: compact ? 7 : 8,
            margin: EdgeInsets.only(right: index == normalizedTotal - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: completed ? _sessionAccentColor : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: completed
                    ? _sessionAccentColor.withValues(alpha: 0.4)
                    : _sessionPanelBorderColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SetEntryRow extends StatelessWidget {
  final WorkoutExercise exercise;
  final bool compact;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final bool isCompleted;
  final VoidCallback? onCompleteSet;

  const _SetEntryRow({
    required this.exercise,
    required this.compact,
    required this.weightController,
    required this.repsController,
    required this.isCompleted,
    required this.onCompleteSet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionWidth = constraints.maxWidth < 340 ? 104.0 : 124.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!exercise.isBodyweight) ...[
              Expanded(
                child: _CompactNumberField(
                  controller: weightController,
                  label: 'Carga',
                  suffix: 'kg',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: _CompactNumberField(
                controller: repsController,
                label: 'Reps',
                hint: exercise.targetReps,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: actionWidth,
              height: 52,
              child: FilledButton.icon(
                onPressed: isCompleted ? null : onCompleteSet,
                icon: Icon(isCompleted ? Icons.check_circle : Icons.check),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(isCompleted ? 'Feito' : 'Registrar'),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompactNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final bool decimal;

  const _CompactNumberField({
    required this.controller,
    required this.label,
    this.hint,
    this.suffix,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        fillColor: _sessionInputColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textInputAction: TextInputAction.done,
    );
  }
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage>
    with WidgetsBindingObserver {
  static const _accentColor = Color(0xFF22C55E);

  final _workoutService = WorkoutService();
  final _sessionService = WorkoutSessionService();
  final _draftService = WorkoutSessionDraftService();
  final _homeWidgetService = AppHomeWidgetService();

  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  final List<CompletedSetInput> _completedSets = [];

  late DateTime _startedAt;

  String? _selectedExerciseId;
  WorkoutSessionDraft? _pendingDraft;
  WorkoutSessionRestDraft? _restTimerDraft;
  bool _draftLoaded = false;
  bool _draftApplied = false;
  bool _draftPersisted = false;
  bool _sessionSaved = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startedAt = DateTime.now();
    _loadSavedDraft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_saveDraft());
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_saveDraft());
    }
  }

  Future<void> _loadSavedDraft() async {
    final draft = await _draftService.loadDraft(workoutId: widget.workout.id);

    if (!mounted) return;

    setState(() {
      _pendingDraft = draft;
      _draftPersisted = draft != null;
      _draftLoaded = true;
    });
  }

  void _applyDraftIfAvailable(
    WorkoutSessionDraft? draft,
    List<WorkoutExercise> exercises,
  ) {
    _draftApplied = true;

    if (draft == null) {
      return;
    }

    final exercisesById = {
      for (final exercise in exercises) exercise.id: exercise,
    };

    _startedAt = draft.startedAt;
    _completedSets.clear();
    _restTimerDraft = draft.restTimer;

    for (final item in draft.completedSets) {
      final exercise = exercisesById[item.workoutExerciseId];

      if (exercise == null || item.reps <= 0) {
        continue;
      }

      if (_completedSetsCountFor(exercise.id) >= exercise.sets) {
        continue;
      }

      _completedSets.add(
        CompletedSetInput(
          exercise: exercise,
          setNumber: _completedSetsCountFor(exercise.id) + 1,
          weight: item.weight,
          reps: item.reps,
        ),
      );
    }

    final selectedExercise = exercisesById[draft.selectedExerciseId];

    if (selectedExercise != null && !_isExerciseCompleted(selectedExercise)) {
      _selectedExerciseId = selectedExercise.id;
      _loadExerciseFields(selectedExercise);
    } else {
      _selectedExerciseId = null;
    }
  }

  Future<void> _saveDraft() async {
    if (_sessionSaved) {
      return;
    }

    final restTimerToPersist = _restTimerDraft?.shouldPersist == true
        ? _restTimerDraft
        : null;

    if (_completedSets.isEmpty && restTimerToPersist == null) {
      if (_draftPersisted) {
        await _draftService.clearDraft(workoutId: widget.workout.id);
        _draftPersisted = false;
      }
      return;
    }

    await _draftService.saveDraft(
      workout: widget.workout,
      startedAt: _startedAt,
      selectedExerciseId: _selectedExerciseId,
      completedSets: _completedSets,
      restTimer: restTimerToPersist,
    );
    _draftPersisted = true;
  }

  int _completedSetsCountFor(String exerciseId) {
    return _completedSets.where((item) => item.exercise.id == exerciseId).length;
  }

  bool _isExerciseCompleted(WorkoutExercise exercise) {
    return _completedSetsCountFor(exercise.id) >= exercise.sets;
  }

  bool _isWorkoutCompleted(List<WorkoutExercise> exercises) {
    return exercises.every(_isExerciseCompleted);
  }

  int _nextSetNumberFor(WorkoutExercise exercise) {
    final nextSet = _completedSetsCountFor(exercise.id) + 1;
    return nextSet > exercise.sets ? exercise.sets : nextSet;
  }

  double _suggestedWeightFor(WorkoutExercise exercise) {
    for (final item in _completedSets.reversed) {
      if (item.exercise.id == exercise.id) {
        return item.weight;
      }
    }

    return exercise.currentWeight;
  }

  String _formatWeight(double value) {
    if (value <= 0) return '';
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  void _loadExerciseFields(WorkoutExercise exercise) {
    if (exercise.isBodyweight) {
      _weightController.clear();
    } else {
      _weightController.text = _formatWeight(_suggestedWeightFor(exercise));
    }
    _repsController.clear();
  }

  void _selectExercise(WorkoutExercise exercise) {
    setState(() {
      _selectedExerciseId = exercise.id;
      _loadExerciseFields(exercise);
    });
    unawaited(_saveDraft());
  }

  RestTimerValue? _restTimerValueFor(WorkoutExercise exercise) {
    final restTimerDraft = _restTimerDraft;
    if (restTimerDraft == null) {
      return null;
    }

    if (restTimerDraft.workoutExerciseId != exercise.id) {
      return null;
    }

    if (restTimerDraft.completedSetsCount != _completedSetsCountFor(exercise.id)) {
      return null;
    }

    return restTimerDraft.timer;
  }

  void _handleRestTimerChanged(
    WorkoutExercise exercise,
    RestTimerValue timerValue,
  ) {
    _restTimerDraft = timerValue.isModified
        ? WorkoutSessionRestDraft(
            workoutExerciseId: exercise.id,
            completedSetsCount: _completedSetsCountFor(exercise.id),
            timer: timerValue,
          )
        : null;

    unawaited(_saveDraft());
  }

  WorkoutExercise _resolveSelectedExercise(List<WorkoutExercise> exercises) {
    for (final exercise in exercises) {
      if (exercise.id == _selectedExerciseId) {
        return exercise;
      }
    }

    for (final exercise in exercises) {
      if (!_isExerciseCompleted(exercise)) {
        return exercise;
      }
    }

    return exercises.first;
  }

  Future<void> _completeSet(
    WorkoutExercise exercise,
    List<WorkoutExercise> exercises,
  ) async {
    if (_isExerciseCompleted(exercise)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Todas as series deste exercicio ja foram registradas.',
          ),
        ),
      );
      return;
    }

    final weight =
        double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ?? 0;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;

    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe as repeticoes realizadas.')),
      );
      return;
    }

    _completedSets.add(
      CompletedSetInput(
        exercise: exercise,
        setNumber: _nextSetNumberFor(exercise),
        weight: weight,
        reps: reps,
      ),
    );

    setState(() {
      _repsController.clear();

      if (_isExerciseCompleted(exercise)) {
        for (final item in exercises) {
          if (!_isExerciseCompleted(item)) {
            _selectedExerciseId = item.id;
            _loadExerciseFields(item);
            break;
          }
        }
      }
    });

    await _saveDraft();
  }

  Future<void> _finishWorkout() async {
    setState(() => _saving = true);

    try {
      await _saveDraft();
      await _sessionService.finishWorkoutSession(
        workout: widget.workout,
        startedAt: _startedAt,
        completedSets: _completedSets,
      );
      await _homeWidgetService.syncFromAppState();
      await _draftService.clearDraft(workoutId: widget.workout.id);
      _draftPersisted = false;
      _sessionSaved = true;

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
              child: Text('Este treino nao possui exercicios.'),
            ),
          );
        }

        if (!_draftLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_draftApplied) {
          _applyDraftIfAvailable(_pendingDraft, exercises);
        }

        final isWorkoutCompleted = _isWorkoutCompleted(exercises);

        if (_selectedExerciseId == null) {
          final initialExercise = _resolveSelectedExercise(exercises);
          _selectedExerciseId = initialExercise.id;
          _loadExerciseFields(initialExercise);
        }

        if (isWorkoutCompleted) {
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
                      color: _accentColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Treino concluido!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_completedSets.length} series registradas',
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

        final exercise = _resolveSelectedExercise(exercises);
        final currentSet = _nextSetNumberFor(exercise);
        final completedExercises = exercises.where(_isExerciseCompleted).length;
        final totalVolume = _completedSets.fold<double>(
          0,
          (sum, item) => sum + item.volume,
        );

        return _CompactWorkoutSessionScaffold(
          workoutName: widget.workout.name,
          exercises: exercises,
          selectedExercise: exercise,
          subtitle: _exerciseSubtitle(exercise),
          currentSet: currentSet,
          completedExercises: completedExercises,
          completedSets: _completedSets.length,
          selectedCompletedSets: _completedSetsCountFor(exercise.id),
          totalVolume: totalVolume,
          completedSetsFor: _completedSetsCountFor,
          isExerciseCompleted: _isExerciseCompleted,
          weightController: _weightController,
          repsController: _repsController,
          restTimerValue: _restTimerValueFor(exercise),
          onExerciseSelected: _selectExercise,
          onRestTimerChanged: (value) =>
              _handleRestTimerChanged(exercise, value),
          onCompleteSet: _isExerciseCompleted(exercise)
              ? null
              : () => _completeSet(exercise, exercises),
        );

      },
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
}


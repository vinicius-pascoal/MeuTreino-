import 'package:flutter/material.dart';

import '../../../core/widgets/app_page_scaffold.dart';
import '../../home_widgets/data/app_home_widget_service.dart';
import '../../workouts/data/workout_service.dart';
import '../../workouts/models/workout.dart';
import '../data/workout_plan_service.dart';
import '../models/workout_plan.dart';

class WorkoutPlanPage extends StatefulWidget {
  const WorkoutPlanPage({super.key});

  @override
  State<WorkoutPlanPage> createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  final _workoutService = WorkoutService();
  final _planService = WorkoutPlanService();
  final _homeWidgetService = AppHomeWidgetService();

  final List<String> _selectedWorkoutIds = [];
  final List<int> _selectedWeekDays = [1, 2, 3, 4, 5];

  bool _loading = true;
  bool _saving = false;
  List<Workout> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final results = await Future.wait([
      _workoutService.getWorkoutsOnce(),
      _planService.getPlanOnce(),
    ]);
    final workouts = results[0] as List<Workout>;
    final existingPlan = results[1] as WorkoutPlan?;

    _selectedWorkoutIds
      ..clear()
      ..addAll(existingPlan?.sequenceWorkoutIds ?? const <String>[]);
    _selectedWeekDays
      ..clear()
      ..addAll(
        existingPlan?.trainingWeekDays.isNotEmpty == true
            ? existingPlan!.trainingWeekDays
            : const [1, 2, 3, 4, 5],
      );

    setState(() {
      _workouts = workouts;
      _loading = false;
    });
  }

  Future<void> _savePlan() async {
    if (_selectedWorkoutIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um treino.')),
      );
      return;
    }

    if (_selectedWeekDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um dia esperado de treino.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _planService.savePlan(
        sequenceWorkoutIds: _selectedWorkoutIds,
        trainingWeekDays: _selectedWeekDays,
      );
      await _homeWidgetService.syncFromAppState();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino semanal salvo com sucesso.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar treino semanal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _toggleWorkout(String workoutId) {
    setState(() {
      if (_selectedWorkoutIds.contains(workoutId)) {
        _selectedWorkoutIds.remove(workoutId);
      } else {
        _selectedWorkoutIds.add(workoutId);
      }
    });
  }

  void _toggleWeekDay(int day) {
    setState(() {
      if (_selectedWeekDays.contains(day)) {
        _selectedWeekDays.remove(day);
      } else {
        _selectedWeekDays.add(day);
        _selectedWeekDays.sort();
      }
    });
  }

  String _dayLabel(int day) {
    switch (day) {
      case 1:
        return 'Seg';
      case 2:
        return 'Ter';
      case 3:
        return 'Qua';
      case 4:
        return 'Qui';
      case 5:
        return 'Sex';
      case 6:
        return 'Sab';
      case 7:
        return 'Dom';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AppPageScaffold(
      title: 'Editar treino semanal',
      currentIndex: 1,
      bottomAction: SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: _saving ? null : _savePlan,
          icon: const Icon(Icons.save),
          label: Text(_saving ? 'Salvando...' : 'Salvar treino semanal'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        children: [
          const Text(
            'Monte a ordem da sua semana.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escolha a sequencia dos treinos e os dias esperados para manter a rotina organizada.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          if (_workouts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Voce ainda nao criou treinos. Crie o Treino A, B e C antes de montar sua semana.',
                ),
              ),
            ),
          ..._workouts.map((workout) {
            final selected = _selectedWorkoutIds.contains(workout.id);
            final order = selected
                ? _selectedWorkoutIds.indexOf(workout.id) + 1
                : null;

            return Card(
              child: CheckboxListTile(
                value: selected,
                onChanged: (_) => _toggleWorkout(workout.id),
                title: Text(workout.name),
                subtitle: Text(
                  selected
                      ? 'Ordem na semana: $order'
                      : workout.description,
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Dias esperados de treino',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final day = index + 1;
              final selected = _selectedWeekDays.contains(day);

              return FilterChip(
                label: Text(_dayLabel(day)),
                selected: selected,
                onSelected: (_) => _toggleWeekDay(day),
              );
            }),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/widgets/app_page_scaffold.dart';
import '../data/workout_automation_service.dart';

class AutoWorkoutPage extends StatefulWidget {
  const AutoWorkoutPage({super.key});

  @override
  State<AutoWorkoutPage> createState() => _AutoWorkoutPageState();
}

class _AutoWorkoutPageState extends State<AutoWorkoutPage> {
  final _automationService = WorkoutAutomationService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repsController = TextEditingController(text: '8-10');
  final _weightController = TextEditingController(text: '0');

  final List<String> _availableGroups = const [
    'Peito',
    'Costas',
    'Ombro',
    'B\u00edceps',
    'Tr\u00edceps',
    'Pernas',
    'Abd\u00f4men',
  ];

  final List<String> _selectedGroups = [];
  final Map<String, int> _exercisesPerGroup = {};

  int _sets = 3;
  int _restSeconds = 90;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _toggleGroup(String group) {
    setState(() {
      if (_selectedGroups.contains(group)) {
        _selectedGroups.remove(group);
        _exercisesPerGroup.remove(group);
      } else {
        _selectedGroups.add(group);
        _exercisesPerGroup[group] = _exercisesPerGroup[group] ?? 2;
      }
    });
  }

  void _updateGroupExerciseCount(String group, int value) {
    setState(() {
      _exercisesPerGroup[group] = value;
    });
  }

  Future<void> _generateWorkout() async {
    setState(() => _loading = true);

    try {
      await _automationService.generateWorkout(
        name: _nameController.text,
        description: _descriptionController.text,
        muscleGroups: _selectedGroups,
        exercisesPerGroup: {
          for (final group in _selectedGroups) group: _exercisesPerGroup[group] ?? 2,
        },
        sets: _sets,
        targetReps: _repsController.text.trim(),
        restSeconds: _restSeconds,
        currentWeight:
            double.tryParse(
              _weightController.text.trim().replaceAll(',', '.'),
            ) ??
            0,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino automatico criado com sucesso.')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao gerar treino: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _suggestedName() {
    if (_selectedGroups.isEmpty) return '';

    return 'Treino ${_selectedGroups.join(", ")}';
  }

  void _useSuggestedName() {
    final suggestion = _suggestedName();

    if (suggestion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um grupo muscular.'),
        ),
      );
      return;
    }

    setState(() {
      _nameController.text = suggestion;
      _descriptionController.text =
          'Treino gerado automaticamente para ${_selectedGroups.join(", ")}.';
    });
  }

  int get _estimatedExerciseCount {
    return _selectedGroups.fold<int>(
      0,
      (sum, group) => sum + (_exercisesPerGroup[group] ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Montar treino automatico',
      currentIndex: 4,
      bottomAction: SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: _loading ? null : _generateWorkout,
          icon: const Icon(Icons.auto_awesome),
          label: _loading
              ? const Text('Gerando treino...')
              : const Text('Gerar treino'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        children: [
          const Text(
            'Escolha os grupos musculares',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'O app busca exercicios da biblioteca e monta um treino equilibrado para cada grupo selecionado.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableGroups.map((group) {
              final selected = _selectedGroups.contains(group);

              return FilterChip(
                label: Text(group),
                selected: selected,
                onSelected: (_) => _toggleGroup(group),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _useSuggestedName,
              icon: const Icon(Icons.lightbulb),
              label: const Text('Usar nome sugerido'),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do treino',
              hintText: 'Ex: Treino Costas e B\u00edceps',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descricao',
              hintText: 'Ex: Treino gerado automaticamente',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quantidade por grupo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (_selectedGroups.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Selecione um ou mais grupos para definir quantos exercicios cada um tera.',
                ),
              ),
            )
          else
            ..._selectedGroups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NumberSelector(
                  title: group,
                  value: _exercisesPerGroup[group] ?? 2,
                  min: 1,
                  max: 8,
                  onChanged: (value) => _updateGroupExerciseCount(group, value),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Configuracao dos exercicios',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _NumberSelector(
            title: 'Series por exercicio',
            value: _sets,
            min: 1,
            max: 6,
            onChanged: (value) {
              setState(() {
                _sets = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _NumberSelector(
            title: 'Descanso em segundos',
            value: _restSeconds,
            min: 30,
            max: 180,
            step: 15,
            onChanged: (value) {
              setState(() {
                _restSeconds = value;
              });
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _repsController,
            decoration: const InputDecoration(
              labelText: 'Repeticoes',
              hintText: 'Ex: 8-10',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Carga inicial',
              suffixText: 'kg',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _selectedGroups.isEmpty
                    ? 'Selecione os grupos musculares para visualizar a previsao.'
                    : 'Previsao: ate $_estimatedExerciseCount exercicios no treino.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberSelector extends StatelessWidget {
  final String title;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _NumberSelector({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  void _decrease() {
    final nextValue = value - step;

    if (nextValue < min) return;

    onChanged(nextValue);
  }

  void _increase() {
    final nextValue = value + step;

    if (nextValue > max) return;

    onChanged(nextValue);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('$value'),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              onPressed: value <= min ? null : _decrease,
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              onPressed: value >= max ? null : _increase,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

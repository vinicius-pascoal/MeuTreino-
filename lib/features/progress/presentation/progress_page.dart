import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_page_scaffold.dart';
import '../../workout_session/data/workout_session_service.dart';
import '../../workout_session/models/performed_set.dart';
import '../../workout_session/models/workout_session_summary.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = WorkoutSessionService();

    return AppPageScaffold(
      title: 'Progresso',
      currentIndex: 3,
      body: StreamBuilder<List<WorkoutSessionSummary>>(
        stream: service.watchRecentSessions(limit: 100),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data!;

          return FutureBuilder<Map<String, List<PerformedSet>>>(
            future: service.getSetsBySessionIds(
              sessions.take(24).map((session) => session.id).toList(),
            ),
            builder: (context, setsSnapshot) {
              if (setsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final setsBySession = setsSnapshot.data ?? const {};
              final allSets = setsBySession.values.expand((sets) => sets).toList();

              final totalWorkouts = sessions.length;
              final totalVolume = sessions.fold<double>(
                0,
                (sum, item) => sum + item.totalVolume,
              );
              final totalSets = sessions.fold<int>(
                0,
                (sum, item) => sum + item.totalSets,
              );
              final averageVolume = totalWorkouts == 0
                  ? 0.0
                  : totalVolume / totalWorkouts;
              final weeklyTrend = _buildTrendData(sessions.take(7).toList().reversed.toList());
              final groupStats = _buildMuscleGroupStats(allSets);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                children: [
                  _SummaryPanel(
                    totalWorkouts: totalWorkouts,
                    totalVolume: totalVolume,
                    totalSets: totalSets,
                    averageVolume: averageVolume,
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    title: 'Ritmo recente',
                    subtitle: 'Ultimos treinos em uma leitura mais visual.',
                  ),
                  const SizedBox(height: 12),
                  _TrendChart(data: weeklyTrend),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    title: 'Grupos musculares',
                    subtitle: 'Volume e numero de series concentrados por grupo.',
                  ),
                  const SizedBox(height: 12),
                  if (groupStats.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Finalize alguns treinos para liberar a analise por grupo muscular.',
                        ),
                      ),
                    )
                  else
                    ...groupStats.map((group) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MuscleGroupCard(
                          stat: group,
                          maxVolume: groupStats.first.volume,
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    title: 'Ultimos treinos',
                    subtitle: 'Historico compacto com volume e densidade.',
                  ),
                  const SizedBox(height: 12),
                  ...sessions.take(10).map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecentSessionCard(
                        session: session,
                        sets: setsBySession[session.id] ?? const [],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<_TrendPoint> _buildTrendData(List<WorkoutSessionSummary> sessions) {
    if (sessions.isEmpty) return const [];

    final formatter = DateFormat('dd/MM');
    return sessions.map((session) {
      final label = session.finishedAt == null
          ? session.workoutName
          : formatter.format(session.finishedAt!);

      return _TrendPoint(
        label: label,
        value: session.totalVolume,
        sets: session.totalSets,
      );
    }).toList();
  }

  List<_MuscleGroupStat> _buildMuscleGroupStats(List<PerformedSet> sets) {
    final grouped = <String, _MuscleGroupAccumulator>{};

    for (final set in sets) {
      final key = set.muscleGroup.trim().isEmpty ? 'Outros' : set.muscleGroup;
      final current = grouped.putIfAbsent(key, _MuscleGroupAccumulator.new);
      current.sets += 1;
      current.volume += set.volume;
      current.maxWeight = math.max(current.maxWeight, set.weight);
      current.exercises.add(set.exerciseName);
    }

    final result = grouped.entries.map((entry) {
      return _MuscleGroupStat(
        name: entry.key,
        sets: entry.value.sets,
        volume: entry.value.volume,
        maxWeight: entry.value.maxWeight,
        exerciseCount: entry.value.exercises.length,
      );
    }).toList();

    result.sort((a, b) => b.volume.compareTo(a.volume));
    return result;
  }
}

class _SummaryPanel extends StatelessWidget {
  final int totalWorkouts;
  final double totalVolume;
  final int totalSets;
  final double averageVolume;

  const _SummaryPanel({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalSets,
    required this.averageVolume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18314E), Color(0xFF0D1E32), Color(0xFF0A1627)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panorama geral',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seu progresso com leitura mais visual e comparavel.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Treinos',
                  value: '$totalWorkouts',
                  accent: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Series',
                  value: '$totalSets',
                  accent: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Volume',
                  value: '${totalVolume.toStringAsFixed(0)} kg',
                  accent: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Media',
                  value: '${averageVolume.toStringAsFixed(0)} kg',
                  accent: const Color(0xFFF472B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<_TrendPoint> data;

  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('Ainda nao ha treinos suficientes para montar o grafico.'),
        ),
      );
    }

    final maxValue = data.fold<double>(0, (max, item) => math.max(max, item.value));
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Volume por treino',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((point) {
                  final heightFactor = point.value / safeMax;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            point.value.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 110 * heightFactor.clamp(0.12, 1.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFF22C55E), Color(0xFF38BDF8)],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            point.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${point.sets} s',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuscleGroupCard extends StatelessWidget {
  final _MuscleGroupStat stat;
  final double maxVolume;

  const _MuscleGroupCard({required this.stat, required this.maxVolume});

  @override
  Widget build(BuildContext context) {
    final progress = maxVolume <= 0 ? 0.0 : stat.volume / maxVolume;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stat.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${stat.volume.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Series',
                    value: '${stat.sets}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniMetric(
                    label: 'Exercicios',
                    value: '${stat.exerciseCount}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniMetric(
                    label: 'Pico',
                    value: '${stat.maxWeight.toStringAsFixed(0)} kg',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  final WorkoutSessionSummary session;
  final List<PerformedSet> sets;

  const _RecentSessionCard({required this.session, required this.sets});

  @override
  Widget build(BuildContext context) {
    final date = session.finishedAt == null
        ? '-'
        : DateFormat('dd/MM HH:mm').format(session.finishedAt!);
    final groups = sets.map((set) => set.muscleGroup).where((group) => group.isNotEmpty).toSet();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.workoutName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(date, style: const TextStyle(color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${session.totalVolume.toStringAsFixed(0)} kg • ${session.totalSets} series',
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: groups.take(4).map((group) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      group,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendPoint {
  final String label;
  final double value;
  final int sets;

  const _TrendPoint({
    required this.label,
    required this.value,
    required this.sets,
  });
}

class _MuscleGroupStat {
  final String name;
  final int sets;
  final double volume;
  final double maxWeight;
  final int exerciseCount;

  const _MuscleGroupStat({
    required this.name,
    required this.sets,
    required this.volume,
    required this.maxWeight,
    required this.exerciseCount,
  });
}

class _MuscleGroupAccumulator {
  int sets = 0;
  double volume = 0;
  double maxWeight = 0;
  final Set<String> exercises = {};
}

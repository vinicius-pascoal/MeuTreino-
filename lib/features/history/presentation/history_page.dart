import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/navigation/app_navigation_state_service.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../workout_session/data/workout_session_service.dart';
import '../../workout_session/models/performed_set.dart';
import '../../workout_session/models/workout_session_summary.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = WorkoutSessionService();
    final navigationStateService = AppNavigationStateService();

    return AppPageScaffold(
      title: 'Evolucao',
      currentIndex: 2,
      body: StreamBuilder<List<WorkoutSessionSummary>>(
        stream: service.watchRecentSessions(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data!;

          if (sessions.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
              children: const [
                SizedBox(height: 20),
                _EmptyEvolutionCard(),
              ],
            );
          }

          final analyticSessionIds = sessions
              .take(24)
              .map((session) => session.id)
              .toList();

          return FutureBuilder<Map<String, List<PerformedSet>>>(
            future: service.getSetsBySessionIds(analyticSessionIds),
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
              final averageSets = totalWorkouts == 0
                  ? 0.0
                  : totalSets / totalWorkouts;
              final averageVolume = totalWorkouts == 0
                  ? 0.0
                  : totalVolume / totalWorkouts;
              final averageDurationMinutes = _averageDurationMinutes(sessions);
              final activeDaysLast30 = _countActiveDaysInRange(
                sessions,
                days: 30,
              );
              final bestRecentSession = _bestRecentSession(sessions);
              final recentVolumeChange = _recentVolumeChange(sessions);
              final recentTrend = _buildTrendData(
                sessions.take(7).toList().reversed.toList(),
              );
              final groupStats = _buildMuscleGroupStats(allSets);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                children: [
                  _SummaryPanel(
                    totalWorkouts: totalWorkouts,
                    totalVolume: totalVolume,
                    totalSets: totalSets,
                    averageVolume: averageVolume,
                    recentVolumeChange: recentVolumeChange,
                  ),
                  const SizedBox(height: 24),
                  const AppSectionHeader(
                    title: 'Destaques',
                    subtitle:
                        'Sinais rapidos para entender frequencia, densidade e ritmo recente.',
                  ),
                  const SizedBox(height: 12),
                  _HighlightsGrid(
                    averageSets: averageSets,
                    averageDurationMinutes: averageDurationMinutes,
                    activeDaysLast30: activeDaysLast30,
                    lastSessionDate: sessions.first.finishedAt,
                  ),
                  if (bestRecentSession != null) ...[
                    const SizedBox(height: 12),
                    _BestSessionCard(session: bestRecentSession),
                  ],
                  const SizedBox(height: 24),
                  const AppSectionHeader(
                    title: 'Ritmo recente',
                    subtitle:
                        'Leitura visual dos ultimos treinos para comparar carga e consistencia.',
                  ),
                  const SizedBox(height: 12),
                  _TrendChart(data: recentTrend),
                  const SizedBox(height: 24),
                  const AppSectionHeader(
                    title: 'Grupos musculares',
                    subtitle:
                        'Volume, series e pico de carga por area trabalhada recentemente.',
                  ),
                  const SizedBox(height: 12),
                  if (groupStats.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Finalize mais treinos para liberar a leitura por grupo muscular.',
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
                  const AppSectionHeader(
                    title: 'Historico de treinos',
                    subtitle:
                        'Abra uma sessao para revisar cargas, series e comparar sua evolucao treino a treino.',
                  ),
                  const SizedBox(height: 12),
                  ...sessions.map((session) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HistorySessionCard(
                        session: session,
                        sets: setsBySession[session.id] ?? const [],
                        onTap: () {
                          unawaited(
                            navigationStateService.pushTrackedPage(
                              context: context,
                              pageState: PersistedPageState.historyDetail(
                                sessionId: session.id,
                              ),
                              builder: (_) =>
                                  HistoryDetailPage(session: session),
                            ),
                          );
                        },
                      ),
                    );
                  }),
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

  double _averageDurationMinutes(List<WorkoutSessionSummary> sessions) {
    if (sessions.isEmpty) return 0;

    final totalDurationSeconds = sessions.fold<int>(
      0,
      (sum, item) => sum + item.durationSeconds,
    );

    return totalDurationSeconds / sessions.length / 60;
  }

  int _countActiveDaysInRange(
    List<WorkoutSessionSummary> sessions, {
    required int days,
  }) {
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final cutoff = normalizedToday.subtract(Duration(days: days - 1));

    return sessions
        .where((session) => session.finishedAt != null)
        .map((session) => session.finishedAt!)
        .map((date) => DateTime(date.year, date.month, date.day))
        .where((date) => !date.isBefore(cutoff))
        .toSet()
        .length;
  }

  WorkoutSessionSummary? _bestRecentSession(
    List<WorkoutSessionSummary> sessions,
  ) {
    if (sessions.isEmpty) return null;

    final recentSessions = sessions.take(10).toList();
    return recentSessions.reduce((best, current) {
      return current.totalVolume > best.totalVolume ? current : best;
    });
  }

  double? _recentVolumeChange(List<WorkoutSessionSummary> sessions) {
    if (sessions.length < 6) return null;

    final recentAverage =
        sessions.take(3).fold<double>(
          0,
          (sum, session) => sum + session.totalVolume,
        ) /
        3;
    final previousAverage =
        sessions.skip(3).take(3).fold<double>(
          0,
          (sum, session) => sum + session.totalVolume,
        ) /
        3;

    if (previousAverage <= 0) return null;

    return ((recentAverage - previousAverage) / previousAverage) * 100;
  }
}

String _formatRelativeDate(DateTime? date) {
  if (date == null) return '-';

  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final difference = normalizedToday.difference(normalizedDate).inDays;

  if (difference <= 0) return 'Hoje';
  if (difference == 1) return 'Ontem';
  if (difference < 7) return '${difference}d atras';

  return DateFormat('dd/MM').format(date);
}

String _formatDuration(int totalSeconds) {
  final totalMinutes = (totalSeconds / 60).round();
  if (totalMinutes <= 0) return '-';

  if (totalMinutes < 60) {
    return '$totalMinutes min';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) {
    return '${hours}h';
  }

  return '${hours}h ${minutes}min';
}

class _EmptyEvolutionCard extends StatelessWidget {
  const _EmptyEvolutionCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppThemeColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: AppThemeColors.primaryStrong,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum treino finalizado ainda',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Quando voce concluir sua primeira sessao, esta tela vai reunir historico, volume e comparacoes recentes em um unico lugar.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySessionCard extends StatelessWidget {
  final WorkoutSessionSummary session;
  final List<PerformedSet> sets;
  final VoidCallback onTap;

  const _HistorySessionCard({
    required this.session,
    required this.sets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = session.finishedAt == null
        ? '-'
        : DateFormat('dd/MM/yyyy HH:mm').format(session.finishedAt!);
    final durationLabel = _formatDuration(session.durationSeconds);
    final groups = sets
        .map((set) => set.muscleGroup.trim())
        .where((group) => group.isNotEmpty)
        .toSet();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppThemeColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: AppThemeColors.primaryStrong,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.workoutName,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(date, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SessionMetaChip(
                          label: '${session.totalSets} series',
                          tone: AppThemeColors.secondary,
                        ),
                        _SessionMetaChip(
                          label: '${session.totalVolume.toStringAsFixed(0)} kg',
                          tone: AppThemeColors.warning,
                        ),
                        if (durationLabel != '-')
                          _SessionMetaChip(
                            label: durationLabel,
                            tone: AppThemeColors.primaryStrong,
                          ),
                      ],
                    ),
                    if (groups.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: groups.take(4).map((group) {
                          return _SessionGroupChip(label: group);
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppThemeColors.textSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionGroupChip extends StatelessWidget {
  final String label;

  const _SessionGroupChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppThemeColors.textMuted,
        ),
      ),
    );
  }
}

class _SessionMetaChip extends StatelessWidget {
  final String label;
  final Color tone;

  const _SessionMetaChip({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final int totalWorkouts;
  final double totalVolume;
  final int totalSets;
  final double averageVolume;
  final double? recentVolumeChange;

  const _SummaryPanel({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalSets,
    required this.averageVolume,
    required this.recentVolumeChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemeColors.surfaceHigh.withValues(alpha: 0.98),
            AppThemeColors.surface.withValues(alpha: 0.94),
          ],
        ),
        border: Border.all(color: AppThemeColors.outlineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Painel unificado', style: theme.textTheme.labelMedium),
          const SizedBox(height: 10),
          Text(
            'Historico e progresso no mesmo painel.',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Volume, densidade e consistencia em uma unica leitura.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _MomentumBadge(change: recentVolumeChange),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Treinos',
                  value: '$totalWorkouts',
                  accent: AppThemeColors.primaryStrong,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Series',
                  value: '$totalSets',
                  accent: AppThemeColors.secondary,
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
                  accent: AppThemeColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Media',
                  value: '${averageVolume.toStringAsFixed(0)} kg',
                  accent: AppThemeColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MomentumBadge extends StatelessWidget {
  final double? change;

  const _MomentumBadge({required this.change});

  @override
  Widget build(BuildContext context) {
    final hasChange = change != null;
    final positive = (change ?? 0) >= 0;
    final tone = hasChange
        ? (positive ? AppThemeColors.primaryStrong : AppThemeColors.warning)
        : AppThemeColors.textMuted;
    final background = hasChange
        ? tone.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.05);
    final icon = hasChange
        ? (positive ? Icons.trending_up_rounded : Icons.trending_down_rounded)
        : Icons.insights_outlined;
    final label = hasChange
        ? '${positive ? '+' : ''}${change!.toStringAsFixed(0)}% de volume medio nas ultimas 3 sessoes.'
        : 'Comparativo recente liberado apos pelo menos 6 treinos.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasChange ? tone.withValues(alpha: 0.18) : AppThemeColors.outline,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightsGrid extends StatelessWidget {
  final double averageSets;
  final double averageDurationMinutes;
  final int activeDaysLast30;
  final DateTime? lastSessionDate;

  const _HighlightsGrid({
    required this.averageSets,
    required this.averageDurationMinutes,
    required this.activeDaysLast30,
    required this.lastSessionDate,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _HighlightCardData(
        icon: Icons.history_toggle_off_rounded,
        label: 'Ultimo treino',
        value: _formatRelativeDate(lastSessionDate),
        accent: AppThemeColors.primaryStrong,
      ),
      _HighlightCardData(
        icon: Icons.stacked_bar_chart_rounded,
        label: 'Media de series',
        value: averageSets.toStringAsFixed(1),
        accent: AppThemeColors.secondary,
      ),
      _HighlightCardData(
        icon: Icons.timer_outlined,
        label: 'Tempo medio',
        value: _formatDuration((averageDurationMinutes * 60).round()),
        accent: AppThemeColors.warning,
      ),
      _HighlightCardData(
        icon: Icons.calendar_month_outlined,
        label: 'Ativos 30d',
        value: '$activeDaysLast30 dias',
        accent: AppThemeColors.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) {
            return SizedBox(
              width: itemWidth,
              child: _HighlightCard(data: card),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HighlightCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _HighlightCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _HighlightCard extends StatelessWidget {
  final _HighlightCardData data;

  const _HighlightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.accent),
          ),
          const SizedBox(height: 14),
          Text(data.label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: data.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _BestSessionCard extends StatelessWidget {
  final WorkoutSessionSummary session;

  const _BestSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = session.finishedAt == null
        ? '-'
        : DateFormat('dd/MM/yyyy').format(session.finishedAt!);
    final duration = _formatDuration(session.durationSeconds);
    final subtitle =
        '$date · ${session.totalVolume.toStringAsFixed(0)} kg · ${session.totalSets} series'
        '${duration == '-' ? '' : ' · $duration'}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemeColors.primary.withValues(alpha: 0.16),
            AppThemeColors.surfaceHigh.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: AppThemeColors.outlineStrong),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppThemeColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppThemeColors.primaryStrong,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Melhor sessao recente',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Text(session.workoutName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
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

    final maxValue = data.fold<double>(
      0,
      (max, item) => math.max(max, item.value),
    );
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volume por treino',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 184,
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
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 112 * heightFactor.clamp(0.12, 1.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppThemeColors.primary,
                                  AppThemeColors.secondary,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            point.label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${point.sets} s',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppThemeColors.textSoft),
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${stat.volume.toStringAsFixed(0)} kg',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppThemeColors.primaryStrong,
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
                valueColor: const AlwaysStoppedAnimation(
                  AppThemeColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(label: 'Series', value: '${stat.sets}'),
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
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
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

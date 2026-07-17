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
import 'muscle_body_progress_map_card.dart';

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
              children: const [SizedBox(height: 20), _EmptyEvolutionCard()],
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
              final allSets = setsBySession.values
                  .expand((sets) => sets)
                  .toList();
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
              final muscleGroupStats = _buildMuscleGroupStats(allSets);
              final muscleMapStats = _buildMuscleEvolutionStats(
                sessions: sessions,
                setsBySession: setsBySession,
              );
              final maxSessionVolume = sessions.fold<double>(
                0,
                (max, session) => math.max(max, session.totalVolume),
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                children: [
                  if (muscleMapStats.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Finalize mais treinos para liberar o mapa muscular.',
                        ),
                      ),
                    )
                  else
                    MuscleBodyProgressMapCard(
                      stats: muscleMapStats
                          .map(
                            (stat) => MuscleBodyProgressStat(
                              name: stat.name,
                              color: stat.color,
                              changeLabel: stat.changeLabel,
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 12),
                  _EvolutionInsightsPanel(
                    averageSets: averageSets,
                    averageVolume: averageVolume,
                    averageDurationMinutes: averageDurationMinutes,
                    activeDaysLast30: activeDaysLast30,
                    lastSessionDate: sessions.first.finishedAt,
                    recentVolumeChange: recentVolumeChange,
                    recentTrend: recentTrend,
                    muscleStats: muscleGroupStats,
                    bestRecentSession: bestRecentSession,
                  ),
                  const SizedBox(height: 24),
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
    }

    final result = grouped.entries.map((entry) {
      return _MuscleGroupStat(
        name: entry.key,
        sets: entry.value.sets,
        volume: entry.value.volume,
      );
    }).toList();

    result.sort((a, b) => b.volume.compareTo(a.volume));
    return result;
  }

  List<_MuscleGroupEvolutionStat> _buildMuscleEvolutionStats({
    required List<WorkoutSessionSummary> sessions,
    required Map<String, List<PerformedSet>> setsBySession,
  }) {
    final recentSessions = sessions.take(6).toList();
    if (recentSessions.length < 2) return const [];

    final sessionVolumes = <Map<String, double>>[];
    final allGroups = <String>{};

    for (final session in recentSessions) {
      final volumesByGroup = <String, double>{};

      for (final set in setsBySession[session.id] ?? const []) {
        final key = set.muscleGroup.trim().isEmpty ? 'Outros' : set.muscleGroup;
        allGroups.add(key);
        volumesByGroup[key] = (volumesByGroup[key] ?? 0) + set.volume;
      }

      sessionVolumes.add(volumesByGroup);
    }

    final result = <_MuscleGroupEvolutionStat>[];

    for (final group in allGroups) {
      final volumes = sessionVolumes
          .map((sessionVolumesByGroup) => sessionVolumesByGroup[group] ?? 0.0)
          .toList();

      final recentCount = math.min(3, volumes.length);
      final previousCount = math.min(3, volumes.length - recentCount);

      if (recentCount == 0 || previousCount == 0) continue;

      final recentAverage =
          volumes
              .take(recentCount)
              .fold<double>(0, (sum, value) => sum + value) /
          recentCount;
      final previousAverage =
          volumes
              .skip(recentCount)
              .take(previousCount)
              .fold<double>(0, (sum, value) => sum + value) /
          previousCount;

      final change = previousAverage <= 0
          ? null
          : ((recentAverage - previousAverage) / previousAverage) * 100;

      result.add(
        _MuscleGroupEvolutionStat(
          name: group,
          currentVolume: recentAverage,
          previousVolume: previousAverage,
          changePercent: change,
        ),
      );
    }

    result.sort((a, b) {
      final scoreA = a.changePercent ?? -9999;
      final scoreB = b.changePercent ?? -9999;
      return scoreB.compareTo(scoreA);
    });

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
        sessions
            .take(3)
            .fold<double>(0, (sum, session) => sum + session.totalVolume) /
        3;
    final previousAverage =
        sessions
            .skip(3)
            .take(3)
            .fold<double>(0, (sum, session) => sum + session.totalVolume) /
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
  final double maxVolume;
  final VoidCallback onTap;

  const _HistorySessionCard({
    required this.session,
    required this.sets,
    required this.maxVolume,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationLabel = _formatDuration(session.durationSeconds);
    final volumeRatio = maxVolume <= 0 ? 0.0 : session.totalVolume / maxVolume;
    final groups = sets
        .map((set) => set.muscleGroup.trim())
        .where((group) => group.isNotEmpty)
        .toSet();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.045),
                Colors.white.withValues(alpha: 0.018),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SessionDateBadge(date: session.finishedAt),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.workoutName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${session.totalVolume.toStringAsFixed(0)} kg',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppThemeColors.primaryStrong,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: volumeRatio.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.07),
                        valueColor: const AlwaysStoppedAnimation(
                          AppThemeColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _SessionMetaChip(
                          label: '${session.totalSets} series',
                          tone: AppThemeColors.secondary,
                        ),
                        if (durationLabel != '-')
                          _SessionMetaChip(
                            label: durationLabel,
                            tone: AppThemeColors.primaryStrong,
                          ),
                        ...groups.take(2).map((group) {
                          return _SessionGroupChip(label: group);
                        }),
                        if (groups.length > 2)
                          _SessionGroupChip(label: '+${groups.length - 2}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

class _SessionDateBadge extends StatelessWidget {
  final DateTime? date;

  const _SessionDateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final day = date == null ? '--' : DateFormat('dd').format(date!);
    final month = date == null ? '--' : DateFormat('MM').format(date!);

    return Container(
      width: 54,
      height: 62,
      decoration: BoxDecoration(
        color: AppThemeColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppThemeColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemeColors.primaryStrong,
            ),
          ),
          Text(
            month,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemeColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppThemeColors.textMuted),
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

class _EvolutionInsightsPanel extends StatelessWidget {
  final double averageSets;
  final double averageVolume;
  final double averageDurationMinutes;
  final int activeDaysLast30;
  final DateTime? lastSessionDate;
  final double? recentVolumeChange;
  final List<_TrendPoint> recentTrend;
  final List<_MuscleGroupStat> muscleStats;
  final WorkoutSessionSummary? bestRecentSession;

  const _EvolutionInsightsPanel({
    required this.averageSets,
    required this.averageVolume,
    required this.averageDurationMinutes,
    required this.activeDaysLast30,
    required this.lastSessionDate,
    required this.recentVolumeChange,
    required this.recentTrend,
    required this.muscleStats,
    required this.bestRecentSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = [
      _InsightMetricData(
        icon: Icons.history_toggle_off_rounded,
        label: 'Ultimo',
        value: _formatRelativeDate(lastSessionDate),
        accent: AppThemeColors.primaryStrong,
      ),
      _InsightMetricData(
        icon: Icons.format_list_numbered_rounded,
        label: 'Series',
        value: averageSets.toStringAsFixed(1),
        accent: AppThemeColors.secondary,
      ),
      _InsightMetricData(
        icon: Icons.timer_outlined,
        label: 'Tempo',
        value: _formatDuration((averageDurationMinutes * 60).round()),
        accent: AppThemeColors.primary,
      ),
      _InsightMetricData(
        icon: Icons.calendar_month_outlined,
        label: '30 dias',
        value: '$activeDaysLast30 dias',
        accent: AppThemeColors.primaryStrong,
      ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppThemeColors.surfaceHigh.withValues(alpha: 0.90),
              AppThemeColors.surface.withValues(alpha: 0.94),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppThemeColors.secondary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    size: 20,
                    color: AppThemeColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumo visual', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Leitura rapida dos ultimos treinos',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InsightMetricGrid(metrics: metrics),
            const SizedBox(height: 12),
            _MomentumBadge(change: recentVolumeChange),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final trendChart = _TrendChart(
                  data: recentTrend,
                  averageVolume: averageVolume,
                );
                final muscleChart = _MuscleVolumeBars(
                  stats: muscleStats.take(5).toList(),
                );

                if (constraints.maxWidth >= 680) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: trendChart),
                      const SizedBox(width: 12),
                      Expanded(child: muscleChart),
                    ],
                  );
                }

                return Column(
                  children: [
                    trendChart,
                    const SizedBox(height: 12),
                    muscleChart,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightMetricGrid extends StatelessWidget {
  final List<_InsightMetricData> metrics;

  const _InsightMetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final columns = isWide ? metrics.length : 2;
        final spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((metric) {
            return SizedBox(
              width: itemWidth,
              child: _InsightMetric(data: metric),
            );
          }).toList(),
        );
      },
    );
  }
}

class _InsightMetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _InsightMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _InsightMetric extends StatelessWidget {
  final _InsightMetricData data;

  const _InsightMetric({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: data.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
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
    final icon = hasChange
        ? (positive ? Icons.trending_up_rounded : Icons.trending_down_rounded)
        : Icons.insights_outlined;
    final title = hasChange
        ? '${positive ? '+' : ''}${change!.toStringAsFixed(0)}% no volume'
        : 'Comparativo pendente';
    final subtitle = hasChange
        ? 'ultimas 3 vs. 3 anteriores'
        : 'precisa de 6 treinos finalizados';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: hasChange ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppThemeColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _BestSessionMini extends StatelessWidget {
  final WorkoutSessionSummary session;

  const _BestSessionMini({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = session.finishedAt == null
        ? '-'
        : DateFormat('dd/MM').format(session.finishedAt!);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemeColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemeColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppThemeColors.primaryStrong,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              session.workoutName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$date  ${session.totalVolume.toStringAsFixed(0)} kg',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppThemeColors.primaryStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<_TrendPoint> data;
  final double averageVolume;

  const _TrendChart({required this.data, required this.averageVolume});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _ChartShell(
        title: 'Volume recente',
        trailing: '',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Center(child: Text('Grafico liberado apos novos treinos.')),
        ),
      );
    }

    final maxValue = data.fold<double>(
      0,
      (max, item) => math.max(max, item.value),
    );
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return _ChartShell(
      title: 'Volume recente',
      trailing: 'media ${averageVolume.toStringAsFixed(0)} kg',
      child: SizedBox(
        height: 156,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((point) {
            final heightFactor = (point.value / safeMax).clamp(0.08, 1.0);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: heightFactor,
                          widthFactor: 0.58,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppThemeColors.primary,
                                  AppThemeColors.secondary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppThemeColors.secondary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Text(
                        point.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      '${point.sets} s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemeColors.textSoft,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MuscleVolumeBars extends StatelessWidget {
  final List<_MuscleGroupStat> stats;

  const _MuscleVolumeBars({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const _ChartShell(
        title: 'Volume por grupo',
        trailing: '',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Center(child: Text('Sem dados musculares ainda.')),
        ),
      );
    }

    final maxVolume = stats.fold<double>(
      0,
      (max, stat) => math.max(max, stat.volume),
    );

    return _ChartShell(
      title: 'Volume por grupo',
      trailing: 'top ${stats.length}',
      child: Column(
        children: stats.map((stat) {
          final progress = maxVolume <= 0 ? 0.0 : stat.volume / maxVolume;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${stat.volume.toStringAsFixed(0)} kg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemeColors.primaryStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: const AlwaysStoppedAnimation(
                      AppThemeColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  final String title;
  final String trailing;
  final Widget child;

  const _ChartShell({
    required this.title,
    required this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (trailing.isNotEmpty)
                Text(
                  trailing,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemeColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
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

  const _MuscleGroupStat({
    required this.name,
    required this.sets,
    required this.volume,
  });
}

class _MuscleGroupEvolutionStat {
  final String name;
  final double currentVolume;
  final double previousVolume;
  final double? changePercent;

  const _MuscleGroupEvolutionStat({
    required this.name,
    required this.currentVolume,
    required this.previousVolume,
    required this.changePercent,
  });

  Color get color {
    if (changePercent == null) {
      return AppThemeColors.textSoft.withValues(alpha: 0.30);
    }

    final normalized = ((changePercent!.clamp(-80, 80)) + 80) / 160;
    return Color.lerp(
          const Color(0xFFE35D5D),
          const Color(0xFF2FBF71),
          normalized,
        ) ??
        AppThemeColors.primary;
  }

  String get changeLabel {
    if (changePercent == null) return 'sem base';

    final sign = changePercent! >= 0 ? '+' : '';
    return '$sign${changePercent!.toStringAsFixed(0)}%';
  }
}

String _normalizeGroupName(String name) {
  return name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[\u00e1\u00e0\u00e2\u00e3\u00e4]'), 'a')
      .replaceAll(RegExp('[\u00e9\u00e8\u00ea\u00eb]'), 'e')
      .replaceAll(RegExp('[\u00ed\u00ec\u00ee\u00ef]'), 'i')
      .replaceAll(RegExp('[\u00f3\u00f2\u00f4\u00f5\u00f6]'), 'o')
      .replaceAll(RegExp('[\u00fa\u00f9\u00fb\u00fc]'), 'u')
      .replaceAll('\u00e7', 'c');
}

class _MuscleGroupAccumulator {
  int sets = 0;
  double volume = 0;
}

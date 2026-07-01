import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../workout_session/data/workout_session_service.dart';
import '../../workout_session/models/performed_set.dart';
import '../../workout_session/models/workout_session_summary.dart';

class HistoryDetailPage extends StatelessWidget {
  final WorkoutSessionSummary session;

  const HistoryDetailPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final service = WorkoutSessionService();

    final date = session.finishedAt == null
        ? '-'
        : DateFormat('dd/MM/yyyy HH:mm').format(session.finishedAt!);

    return AppPageScaffold(
      title: session.workoutName,
      currentIndex: 2,
      body: StreamBuilder<List<PerformedSet>>(
        stream: service.watchSessionSets(sessionId: session.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sets = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
            children: [
              _HistorySummaryCard(
                title: session.workoutName,
                date: date,
                totalSets: session.totalSets,
                totalVolume: session.totalVolume,
              ),
              const SizedBox(height: 24),
              const AppSectionHeader(
                title: 'Series registradas',
                subtitle:
                    'Detalhe das cargas e repeticoes que formaram esta sessao.',
              ),
              const SizedBox(height: 12),
              if (sets.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Nenhuma serie encontrada para esta sessao.'),
                  ),
                )
              else
                ...sets.map(
                  (set) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PerformedSetCard(set: set),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  final String title;
  final String date;
  final int totalSets;
  final double totalVolume;

  const _HistorySummaryCard({
    required this.title,
    required this.date,
    required this.totalSets,
    required this.totalVolume,
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
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(date, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Series',
                  value: '$totalSets',
                  tone: AppThemeColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Volume',
                  value: '${totalVolume.toStringAsFixed(0)} kg',
                  tone: AppThemeColors.primaryStrong,
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
  final Color tone;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

class _PerformedSetCard extends StatelessWidget {
  final PerformedSet set;

  const _PerformedSetCard({required this.set});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppThemeColors.secondary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              '${set.setNumber}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppThemeColors.secondary,
              ),
            ),
          ),
        ),
        title: Text(set.exerciseName, style: theme.textTheme.titleMedium),
        subtitle: Text(
          '${set.muscleGroup} - Serie ${set.setNumber}',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Text(
          '${set.weight.toStringAsFixed(1)} kg x ${set.reps}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppThemeColors.primaryStrong,
          ),
        ),
      ),
    );
  }
}

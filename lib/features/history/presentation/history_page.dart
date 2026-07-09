import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/navigation/app_navigation_state_service.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../workout_session/data/workout_session_service.dart';
import '../../workout_session/models/workout_session_summary.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = WorkoutSessionService();
    final navigationStateService = AppNavigationStateService();

    return AppPageScaffold(
      title: 'Historico',
      currentIndex: 2,
      body: StreamBuilder<List<WorkoutSessionSummary>>(
        stream: service.watchRecentSessions(limit: 80),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
            children: [
              const SizedBox(height: 20),
              if (sessions.isEmpty)
                const _EmptyHistoryCard()
              else
                ...sessions.map((session) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HistorySessionCard(
                      session: session,
                      onTap: () {
                        unawaited(
                          navigationStateService.pushTrackedPage(
                            context: context,
                            pageState: PersistedPageState.historyDetail(
                              sessionId: session.id,
                            ),
                            builder: (_) => HistoryDetailPage(session: session),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

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
                color: AppThemeColors.secondary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppThemeColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum treino realizado ainda',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Assim que voce concluir uma sessao, ela vai aparecer aqui com data, series e volume.',
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
  final VoidCallback onTap;

  const _HistorySessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = session.finishedAt == null
        ? '-'
        : DateFormat('dd/MM/yyyy HH:mm').format(session.finishedAt!);

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
                    Row(
                      children: [
                        _SessionMetaChip(
                          label: '${session.totalSets} series',
                          tone: AppThemeColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        _SessionMetaChip(
                          label: '${session.totalVolume.toStringAsFixed(0)} kg',
                          tone: AppThemeColors.warning,
                        ),
                      ],
                    ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class SprintScreen extends StatelessWidget {
  const SprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final sprint = appState.sprint;
    final df = DateFormat('MMM d');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Sprint Goal', subtitle: 'Construction sprint · 10 days'),
          PremiumCard(
            gradientColors: const [Color(0xFF1B2550), Color(0xFF232E52)],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sprint.goal, style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.date_range_rounded, size: 15, color: AppColors.textSecondary.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Text('${df.format(sprint.startDate)} – ${df.format(sprint.endDate)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    StatusChip(label: '${sprint.daysRemaining}d remaining', color: AppColors.accentAmber),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: ProgressBarLine(percent: sprint.progressPercent)),
                    const SizedBox(width: 10),
                    Text('${sprint.progressPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Current Sprint', subtitle: '${sprint.currentSprint.length} tasks in flight'),
          ...sprint.currentSprint.map((t) => _SprintTaskTile(task: t)),
          const SectionHeader(title: 'Backlog', subtitle: 'Not yet pulled into a sprint'),
          if (sprint.backlog.isEmpty)
            const EmptyState(message: 'Backlog is empty.')
          else
            ...sprint.backlog.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PremiumCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.inbox_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t.title, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                )),
          if (sprint.atRiskTasks.isNotEmpty) ...[
            const SectionHeader(title: 'At-Risk Tasks', subtitle: 'AI-flagged for recovery attention'),
            ...sprint.atRiskTasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PremiumCard(
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${t.progressPercent}% complete · recommend daily check-in',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
          const SectionHeader(title: 'AI Recommendations for Recovery'),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _RecoveryTip(text: 'Escalate Shah Steel delivery today — slab casting is the critical-path item this sprint.'),
                SizedBox(height: 10),
                _RecoveryTip(text: 'Pull 1 extra mason to beam-junction QA fix to protect the sprint goal date.'),
                SizedBox(height: 10),
                _RecoveryTip(text: 'Guard rail install is 70% done — prioritize to close the safety stop-work blocker.'),
              ],
            ),
          ),
          const SectionHeader(title: 'Sprint Review & Retrospective'),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sprint.retrospectiveNotes ??
                      'Review pending — schedule after sprint close. Early signal: '
                      'material delays from external vendors were the top blocker '
                      'source this sprint.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryTip extends StatelessWidget {
  final String text;
  const _RecoveryTip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.accentAmber),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.4))),
      ],
    );
  }
}

class _SprintTaskTile extends StatelessWidget {
  final SprintTaskRef task;
  const _SprintTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(task.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
                if (task.atRisk)
                  const StatusChip(label: 'At Risk', color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: ProgressBarLine(percent: task.progressPercent.toDouble(), color: task.atRisk ? AppColors.warning : AppColors.accentTeal)),
                const SizedBox(width: 10),
                Text('${task.progressPercent}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

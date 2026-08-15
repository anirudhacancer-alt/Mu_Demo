import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class ControlTowerScreen extends StatelessWidget {
  const ControlTowerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Manager Dashboard', subtitle: 'Project-wide health at a glance'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              StatTile(
                label: 'Planned vs Done',
                value: '${appState.plannedVsDoneOverall.toStringAsFixed(0)}%',
                icon: Icons.insights_rounded,
                color: AppColors.accentTeal,
              ),
              StatTile(
                label: 'Open Blockers',
                value: '${appState.blockers.length}',
                icon: Icons.block_rounded,
                color: AppColors.danger,
              ),
              StatTile(
                label: 'Avg Blocker Aging',
                value: '${appState.avgBlockerAgingDays.toStringAsFixed(1)}d',
                icon: Icons.hourglass_bottom_rounded,
                color: AppColors.warning,
              ),
              StatTile(
                label: 'Critical Delays',
                value: '${appState.criticalDelaysCount}',
                icon: Icons.priority_high_rounded,
                color: AppColors.accentCoral,
              ),
              StatTile(
                label: 'Procurement Risks',
                value: '${appState.procurementRiskCount}',
                icon: Icons.local_shipping_rounded,
                color: AppColors.info,
              ),
              StatTile(
                label: 'QA / Rework Items',
                value: '${appState.openSnagsCount}',
                icon: Icons.build_circle_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          const SectionHeader(title: 'Sprint Progress'),
          PremiumCard(
            child: Row(
              children: [
                SizedBox(
                  height: 90,
                  width: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 0,
                          centerSpaceRadius: 30,
                          sections: [
                            PieChartSectionData(
                              value: appState.sprint.progressPercent,
                              color: AppColors.accentTeal,
                              showTitle: false,
                              radius: 14,
                            ),
                            PieChartSectionData(
                              value: 100 - appState.sprint.progressPercent,
                              color: Colors.white.withOpacity(0.08),
                              showTitle: false,
                              radius: 14,
                            ),
                          ],
                        ),
                      ),
                      Text('${appState.sprint.progressPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appState.sprint.goal,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('${appState.sprint.daysRemaining} day(s) remaining · '
                          '${appState.sprint.atRiskTasks.length} task(s) at risk',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Top Project Risks', subtitle: 'Critical-path risk indication'),
          ...appState.tasks
              .where((t) => t.severity == 'Critical' || (t.isBlocker && t.agingDays >= 2))
              .take(3)
              .map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PremiumCard(
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 40,
                            decoration: BoxDecoration(
                              color: severityColor(t.severity),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text('${t.tower} · ${t.floor} — critical path item',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
          const SectionHeader(title: 'AI Risk & Escalation', subtitle: 'Aging blockers, repeated delays, material issues'),
          ...appState.riskAlerts.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  gradientColors: [
                    AppColors.surface,
                    severityColor(r.severity).withOpacity(0.10),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_rounded, size: 16, color: severityColor(r.severity)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          ),
                          SeverityChip(severity: r.severity),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(r.description, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
                      const SizedBox(height: 6),
                      Text('Source: ${r.source}',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.7))),
                    ],
                  ),
                ),
              )),
          const SectionHeader(title: 'Weekly Review Pack', subtitle: 'Auto-compiled management summary'),
          PremiumCard(
            gradientColors: const [Color(0xFF17203E), Color(0xFF1E2A55)],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.summarize_rounded, color: AppColors.accentAmber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(appState.weeklyReviewSummary,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showFullReviewPack(context, appState),
              icon: const Icon(Icons.open_in_full_rounded, size: 16),
              label: const Text('View full review pack'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullReviewPack(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Weekly Review Pack', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _reviewSection('Work Completed', '${appState.tasks.where((t) => t.status == "Resolved").length} tasks resolved this week across all towers.'),
            _reviewSection('Planned vs Done', '${appState.plannedVsDoneOverall.toStringAsFixed(0)}% overall completion rate.'),
            _reviewSection('Major Blockers', appState.blockers.map((b) => '${b.title} (${b.agingDays}d)').join('\n')),
            _reviewSection('Procurement Issues', appState.procurementItems.where((p) => p.status == 'Delayed').map((p) => '${p.material} — ${p.impact}').join('\n')),
            _reviewSection('QA / Safety Issues', appState.snags.where((s) => s.status == 'Open').map((s) => '${s.title} (${s.severity})').join('\n')),
            _reviewSection('Risks for Next Week', appState.riskAlerts.map((r) => r.title).join('\n')),
            _reviewSection('AI Recommendations', 'Prioritize steel & cement vendor escalations; close aging safety blocker first; reallocate 1 crew to QA fix to protect sprint goal.'),
            _reviewSection('Management Summary', appState.weeklyReviewSummary),
          ],
        ),
      ),
    );
  }

  Widget _reviewSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.accentTeal)),
          const SizedBox(height: 6),
          Text(body.isEmpty ? 'None.' : body, style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

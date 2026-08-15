import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class DailyExecutionScreen extends StatelessWidget {
  const DailyExecutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final standup = appState.standups.first;
    final role = appState.currentRole;
    final isFieldRole = role != UserRole.projectManager;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFieldRole) ...[
            const SectionHeader(
              title: "Today's Snapshot",
              subtitle: 'Planned work, blockers and quick actions',
            ),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Planned vs Done',
                    value: '${standup.plannedVsDonePercent.toStringAsFixed(0)}%',
                    icon: Icons.stacked_line_chart_rounded,
                    color: AppColors.accentTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Open Blockers',
                    value: '${appState.blockers.length}',
                    icon: Icons.block_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'QA Snags Open',
                    value: '${appState.openSnagsCount}',
                    icon: Icons.fact_check_rounded,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Material Delays',
                    value: '${appState.procurementRiskCount}',
                    icon: Icons.local_shipping_rounded,
                    color: AppColors.accentCoral,
                  ),
                ),
              ],
            ),
            const SectionHeader(title: 'Quick Actions'),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.mic_rounded,
                    label: 'Record Update',
                    onTap: () => _switchTab(context, 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_a_photo_rounded,
                    label: 'Add Photo',
                    onTap: () => _switchTab(context, 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.groups_rounded,
                    label: 'Start Standup',
                    onTap: () => _scrollToStandup(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.report_problem_rounded,
                    label: 'Report Blocker',
                    onTap: () => _switchTab(context, 1),
                  ),
                ),
              ],
            ),
          ],
          const SectionHeader(
            title: 'Daily Standup',
            subtitle: 'Attendance · planned vs completed · blockers',
          ),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.groups_2_rounded, color: AppColors.accentTeal, size: 18),
                    const SizedBox(width: 8),
                    Text('Attendance: ${standup.present}/${standup.totalCrew}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressBarLine(percent: (standup.present / standup.totalCrew) * 100),
                const SizedBox(height: 18),
                _buildListSection('Planned Yesterday', standup.plannedYesterday, Icons.checklist_rtl_rounded, AppColors.info),
                const SizedBox(height: 14),
                _buildListSection('Completed', standup.completedYesterday, Icons.check_circle_rounded, AppColors.success),
                const SizedBox(height: 14),
                _buildListSection('Blocked', standup.blockedItems, Icons.block_rounded, AppColors.danger),
              ],
            ),
          ),
          const SectionHeader(
            title: 'AI-Generated Standup Summary',
            subtitle: 'Auto-composed from today\'s inputs',
          ),
          PremiumCard(
            gradientColors: const [Color(0xFF17203E), Color(0xFF1E2A55)],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(standup.aiSummary,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('None reported.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))
        else
          ...items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(i, style: const TextStyle(fontSize: 12.5))),
                  ],
                ),
              )),
      ],
    );
  }

  void _switchTab(BuildContext context, int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(index == 0 ? 'Opening Capture module…' : 'Opening Tasks module…')),
    );
  }

  void _scrollToStandup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scroll down to Daily Standup section.')),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentTeal, size: 22),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

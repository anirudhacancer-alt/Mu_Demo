import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class DailyExecutionScreen extends StatelessWidget {
  const DailyExecutionScreen({super.key});

  void _openNewStandupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _NewStandupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final standups = appState.standups;
    final latest = standups.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: "Today's Snapshot",
            subtitle: 'Planned work, blockers and quick actions',
          ),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Planned vs Done',
                  value: '${latest.plannedVsDonePercent.toStringAsFixed(0)}%',
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
                  icon: Icons.groups_rounded,
                  label: 'Start Standup',
                  onTap: () => _openNewStandupSheet(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.report_problem_rounded,
                  label: 'Report Blocker',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open the Tasks tab to report a blocker.')),
                    );
                  },
                ),
              ),
            ],
          ),
          SectionHeader(
            title: 'Daily Standup',
            subtitle: 'Attendance · planned vs completed · blockers · learnings',
            trailing: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openNewStandupSheet(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text('New', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _StandupCard(entry: latest, isLatest: true),
          if (standups.length > 1) ...[
            const SectionHeader(
              title: 'Standup History',
              subtitle: 'A continuous record instead of disappearing after the meeting',
            ),
            ...standups.skip(1).map((e) => _StandupHistoryTile(entry: e)),
          ],
        ],
      ),
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

class _StandupCard extends StatelessWidget {
  final StandupEntry entry;
  final bool isLatest;
  const _StandupCard({required this.entry, this.isLatest = false});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2_rounded, color: AppColors.accentTeal, size: 18),
              const SizedBox(width: 8),
              Text('Attendance: ${entry.present}/${entry.totalCrew}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text(DateFormat('EEE, MMM d').format(entry.date),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBarLine(percent: entry.totalCrew == 0 ? 0 : (entry.present / entry.totalCrew) * 100),
          const SizedBox(height: 18),
          _buildListSection('Planned', entry.plannedYesterday, Icons.checklist_rtl_rounded, AppColors.info),
          const SizedBox(height: 14),
          _buildListSection('Completed', entry.completedYesterday, Icons.check_circle_rounded, AppColors.success),
          const SizedBox(height: 14),
          _buildListSection('Blocked', entry.blockedItems, Icons.block_rounded, AppColors.danger),
          const SizedBox(height: 14),
          _buildListSection('Key Learnings', entry.keyLearnings, Icons.lightbulb_outline_rounded, AppColors.accentAmber),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(entry.aiSummary, style: const TextStyle(fontSize: 12.5, height: 1.5)),
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
}

/// A collapsed history entry — tapping ANYWHERE on the row (not just an
/// icon) expands it in place, keeping the whole element tappable.
class _StandupHistoryTile extends StatefulWidget {
  final StandupEntry entry;
  const _StandupHistoryTile({required this.entry});

  @override
  State<_StandupHistoryTile> createState() => _StandupHistoryTileState();
}

class _StandupHistoryTileState extends State<_StandupHistoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(DateFormat('EEE, MMM d').format(entry.date),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                Text('${entry.plannedVsDonePercent.toStringAsFixed(0)}% done',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                const SizedBox(width: 6),
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Text('Attendance: ${entry.present}/${entry.totalCrew}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Text(entry.aiSummary, style: const TextStyle(fontSize: 12.5, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// The standup reflection input form — captures completed/planned/blockers
/// and key learnings, and saves as a new history entry (rather than the
/// info disappearing after the meeting).
class _NewStandupSheet extends StatefulWidget {
  const _NewStandupSheet();

  @override
  State<_NewStandupSheet> createState() => _NewStandupSheetState();
}

class _NewStandupSheetState extends State<_NewStandupSheet> {
  late int _present;
  late int _totalCrew;
  List<String> _planned = [];
  List<String> _completed = [];
  List<String> _blocked = [];
  List<String> _learnings = [];

  @override
  void initState() {
    super.initState();
    _present = 0;
    _totalCrew = 0;
  }

  Widget _counterField(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Material(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged((value - 1).clamp(0, 999)),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.remove_rounded, size: 18),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        Material(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged((value + 1).clamp(0, 999)),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.add_rounded, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final appState = context.read<AppState>();
    final draft = appState.newEmptyStandupDraft();
    draft.present = _present;
    draft.totalCrew = _totalCrew;
    draft.plannedYesterday = _planned;
    draft.completedYesterday = _completed;
    draft.blockedItems = _blocked;
    draft.keyLearnings = _learnings;
    appState.submitStandup(draft);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Standup saved to history.'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('New Daily Standup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('This becomes part of the continuous standup record.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            _counterField('Present today', _present, (v) => setState(() => _present = v)),
            const SizedBox(height: 10),
            _counterField('Total crew', _totalCrew, (v) => setState(() => _totalCrew = v)),
            const SizedBox(height: 18),
            TagListField(
              label: 'Planned',
              items: _planned,
              chipColor: AppColors.info,
              onChanged: (v) => setState(() => _planned = v),
            ),
            const SizedBox(height: 18),
            TagListField(
              label: 'Completed',
              items: _completed,
              chipColor: AppColors.success,
              onChanged: (v) => setState(() => _completed = v),
            ),
            const SizedBox(height: 18),
            TagListField(
              label: 'Blockers',
              items: _blocked,
              chipColor: AppColors.danger,
              onChanged: (v) => setState(() => _blocked = v),
            ),
            const SizedBox(height: 18),
            TagListField(
              label: 'Key learnings / issues',
              items: _learnings,
              chipColor: AppColors.accentAmber,
              onChanged: (v) => setState(() => _learnings = v),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Standup'),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

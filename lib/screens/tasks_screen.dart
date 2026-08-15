import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Open', 'In Progress', 'Blocked', 'Resolved'];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.tasks.where((t) {
      if (_filter == 'All') return true;
      return t.status == _filter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Open Blockers',
                  value: '${appState.blockers.length}',
                  icon: Icons.block_rounded,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Avg Blocker Aging',
                  value: '${appState.avgBlockerAgingDays.toStringAsFixed(1)}d',
                  icon: Icons.hourglass_bottom_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final selected = f == _filter;
                return ChoiceChip(
                  label: Text(f, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: AppColors.primary.withOpacity(0.35),
                  backgroundColor: AppColors.surfaceLight,
                );
              },
            ),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const EmptyState(message: 'No tasks in this filter.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => _TaskCard(task: tasks[i]),
                ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final SiteTask task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        onTap: () => _showDetail(context, task),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(task.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                ),
                if (task.isBlocker)
                  const Icon(Icons.block_rounded, color: AppColors.danger, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text('${task.tower} · ${task.floor} · ${task.trade}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                TaskStatusChip(status: task.status),
                SeverityChip(severity: task.severity),
                if (task.isBlocker)
                  StatusChip(label: 'Aging ${task.agingDays}d', color: AppColors.accentCoral),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(task.owner, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                const Spacer(),
                const Icon(Icons.event_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_fmtDate(task.dueDate),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, SiteTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _TaskDetailSheet(task: task),
    );
  }
}

String _fmtDate(DateTime d) {
  final now = DateTime.now();
  final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  if (diff < 0) return '${-diff}d overdue';
  return 'Due in ${diff}d';
}

class _TaskDetailSheet extends StatefulWidget {
  final SiteTask task;
  const _TaskDetailSheet({required this.task});

  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  static const statuses = ['Open', 'In Progress', 'Blocked', 'Resolved'];

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
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
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(task.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(task.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(label: '${task.tower} · ${task.floor}', color: AppColors.accentTeal),
                StatusChip(label: task.trade, color: AppColors.info),
                SeverityChip(severity: task.severity),
                if (task.vendor != 'N/A') StatusChip(label: task.vendor, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Owner: ${task.owner}', style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Text(_fmtDate(task.dueDate), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Update status', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: statuses.map((s) {
                final selected = s == task.status;
                return ChoiceChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) {
                    context.read<AppState>().updateTaskStatus(task.id, s);
                    setState(() {});
                  },
                  selectedColor: statusColor(s).withOpacity(0.35),
                  backgroundColor: AppColors.surfaceLight,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class ProcurementQaScreen extends StatefulWidget {
  const ProcurementQaScreen({super.key});

  @override
  State<ProcurementQaScreen> createState() => _ProcurementQaScreenState();
}

class _ProcurementQaScreenState extends State<ProcurementQaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Procurement Tracker'),
              Tab(text: 'QA / Snag Management'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _ProcurementTab(),
              _QaSnagTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProcurementTab extends StatelessWidget {
  const _ProcurementTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = appState.procurementItems;
    final df = DateFormat('MMM d');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Delayed Items',
                value: '${items.where((p) => p.status == "Delayed").length}',
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'In Transit',
                value: '${items.where((p) => p.status == "In Transit").length}',
                icon: Icons.local_shipping_rounded,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'Material Tracker'),
        ...items.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(p.material, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                        StatusChip(label: p.status, color: statusColor(p.status)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Vendor: ${p.vendor}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Linked: ${p.linkedActivity}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgDeep,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Impact: ${p.impact}', style: const TextStyle(fontSize: 12, height: 1.4)),
                          const SizedBox(height: 4),
                          Text('Escalation: ${p.escalationAction}',
                              style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.accentAmber)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Required by ${df.format(p.requiredBy)}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        const Spacer(),
                        _StatusCycleButton(item: p),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _StatusCycleButton extends StatelessWidget {
  final ProcurementItem item;
  const _StatusCycleButton({required this.item});

  static const stages = ['Requested', 'Confirmed', 'In Transit', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final idx = stages.indexOf(item.status);
    final next = idx >= 0 && idx < stages.length - 1 ? stages[idx + 1] : null;
    if (next == null) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: () => context.read<AppState>().updateProcurementStatus(item.id, next),
      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
      label: Text('Mark $next', style: const TextStyle(fontSize: 11.5)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    );
  }
}

class _QaSnagTab extends StatelessWidget {
  const _QaSnagTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final snags = appState.snags;
    final df = DateFormat('MMM d');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Open Snags',
                value: '${snags.where((s) => s.status == "Open").length}',
                icon: Icons.report_problem_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Resolved',
                value: '${snags.where((s) => s.status == "Resolved").length}',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'Snag / Punch List'),
        ...snags.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(s.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                        StatusChip(label: s.status, color: statusColor(s.status)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${s.trade} · Assigned: ${s.assignedTo}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        SeverityChip(severity: s.severity),
                        StatusChip(label: 'Due ${df.format(s.dueDate)}', color: AppColors.textSecondary),
                        if (s.status == 'Resolved')
                          StatusChip(label: s.passFail ? 'Pass' : 'Fail', color: s.passFail ? AppColors.success : AppColors.danger),
                      ],
                    ),
                    if (s.resolutionProof != null) ...[
                      const SizedBox(height: 8),
                      Text('Resolution: ${s.resolutionProof}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                    ],
                    if (s.status == 'Open') ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => context.read<AppState>().resolveSnag(s.id),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Close Snag', style: TextStyle(fontSize: 12.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

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
            // FIX: force the selection indicator to fill the ENTIRE tab
            // segment (not just wrap tightly around the label text). The
            // default TabBarIndicatorSize.label only sizes the indicator to
            // the text width, which looked inconsistent between the two
            // tabs (different label lengths) when switching. indicatorPadding
            // adds a small inset so the pill doesn't touch the edges of its
            // segment, while still covering the full tappable area.
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            splashBorderRadius: BorderRadius.circular(14),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            // Tab already stretches to fill its full segment width/height,
            // so the whole segment (not just the text) is tappable/touchable.
            tabs: const [
              Tab(height: 44, child: Center(child: Text('Procurement Tracker'))),
              Tab(height: 44, child: Center(child: Text('QA / Snag Management'))),
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
                    // FIX: the bottom row now ALWAYS shows something on the
                    // right — either a "Mark <next stage>" action or a
                    // "Completed" indicator for delivered items — instead of
                    // sometimes being empty (as it was for "Delayed" items,
                    // which had no next stage in the old logic and left an
                    // awkward gap next to the required-by date).
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('Required by ${df.format(p.requiredBy)}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ),
                        const Spacer(),
                        _StatusCycleAction(item: p),
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

/// Always renders something in the trailing slot of the material card's
/// bottom row — either a tappable "Mark <next>" action, or a "Completed"
/// marker for terminal (Delivered) items — so every card has consistent
/// visual weight regardless of its current status.
class _StatusCycleAction extends StatelessWidget {
  final ProcurementItem item;
  const _StatusCycleAction({required this.item});

  static const stages = ['Requested', 'Confirmed', 'In Transit', 'Delivered'];

  String? _nextStatus(String current) {
    if (current == 'Delayed') {
      // A resolved delay resumes as "In Transit".
      return 'In Transit';
    }
    final idx = stages.indexOf(current);
    if (idx >= 0 && idx < stages.length - 1) return stages[idx + 1];
    return null; // Delivered — terminal, nothing further to mark.
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(item.status);
    if (next == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
          SizedBox(width: 4),
          Text('Completed', style: TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600)),
        ],
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.read<AppState>().updateProcurementStatus(item.id, next),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Mark $next',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
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

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium translucent card used across dashboards — gives a subtle
/// glass-like feel using gradients + soft borders (no BackdropFilter
/// needed, keeps rendering cheap on lower-end demo devices).
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors ??
                  [AppColors.surface, AppColors.surfaceLight],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class SeverityChip extends StatelessWidget {
  final String severity;
  const SeverityChip({super.key, required this.severity});
  @override
  Widget build(BuildContext context) =>
      StatusChip(label: severity, color: severityColor(severity));
}

class PriorityChip extends StatelessWidget {
  final String priority;
  const PriorityChip({super.key, required this.priority});
  @override
  Widget build(BuildContext context) =>
      StatusChip(label: 'Priority: $priority', color: priorityColor(priority));
}

class TaskStatusChip extends StatelessWidget {
  final String status;
  const TaskStatusChip({super.key, required this.status});
  @override
  Widget build(BuildContext context) =>
      StatusChip(label: status, color: statusColor(status));
}

/// Small badge showing whether a capture/task has synced to Firebase.
/// Shows nothing distracting when Firebase isn't configured at all —
/// only appears once a sync has actually been attempted.
class CloudSyncBadge extends StatelessWidget {
  final String status; // 'local' | 'syncing' | 'synced' | 'failed'
  const CloudSyncBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'local') return const SizedBox.shrink();
    IconData icon;
    String label;
    switch (status) {
      case 'synced':
        icon = Icons.cloud_done_rounded;
        label = 'Synced';
        break;
      case 'syncing':
        icon = Icons.cloud_sync_rounded;
        label = 'Syncing…';
        break;
      default:
        icon = Icons.cloud_off_rounded;
        label = 'Sync failed';
    }
    final color = cloudSyncColor(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class ProgressBarLine extends StatelessWidget {
  final double percent; // 0-100
  final Color color;
  const ProgressBarLine({super.key, required this.percent, this.color = AppColors.accentTeal});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: (percent / 100).clamp(0, 1),
        minHeight: 8,
        backgroundColor: Colors.white.withOpacity(0.08),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// A reusable "tag list" input: shows existing tags as removable chips and
/// an add-row (text field + full-size tappable add button) below. Used for
/// the standup reflection form (planned / completed / blocked / learnings).
class TagListField extends StatefulWidget {
  final String label;
  final List<String> items;
  final String hintText;
  final Color chipColor;
  final ValueChanged<List<String>> onChanged;

  const TagListField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.hintText = 'Type and tap Add…',
    this.chipColor = AppColors.primary,
  });

  @override
  State<TagListField> createState() => _TagListFieldState();
}

class _TagListFieldState extends State<TagListField> {
  final _controller = TextEditingController();

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final updated = [...widget.items, text];
    widget.onChanged(updated);
    _controller.clear();
  }

  void _remove(int index) {
    final updated = [...widget.items]..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        if (widget.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(widget.items.length, (i) {
                return InputChip(
                  label: Text(widget.items[i], style: const TextStyle(fontSize: 12)),
                  onDeleted: () => _remove(i),
                  backgroundColor: widget.chipColor.withOpacity(0.15),
                  deleteIconColor: widget.chipColor,
                  side: BorderSide(color: widget.chipColor.withOpacity(0.3)),
                );
              }),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            // Full-size tappable add button (not just a small icon) so the
            // whole control is easy to tap.
            Material(
              color: widget.chipColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _add,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

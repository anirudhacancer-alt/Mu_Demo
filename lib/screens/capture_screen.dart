import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final List<File> _sessionPhotos = [];
  final List<_ChecklistItem> _checklist = [
    _ChecklistItem('Safety helmets & PPE worn on site'),
    _ChecklistItem('Housekeeping — debris cleared from work zone'),
    _ChecklistItem('Scaffolding & guard rails secured'),
    _ChecklistItem('QA checkpoints signed off before pour/finish'),
  ];

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source, imageQuality: 70);
      if (file != null) {
        setState(() => _sessionPhotos.add(File(file.path)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera/gallery not available on this device.')),
        );
      }
    }
  }

  void _openReflectionSheet(BuildContext context, CapturedUpdate cu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ReflectionSheet(capturedUpdate: cu),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final captures = appState.capturedUpdates;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _VoiceCaptureCard(),
          SectionHeader(
            title: 'Captured Updates',
            subtitle: captures.isEmpty
                ? 'Nothing captured yet — record an update above'
                : '${appState.pendingReflectionCount} awaiting reflection · tap any card to convert',
          ),
          if (captures.isEmpty)
            const EmptyState(
              message: 'Captured voice updates land here first.\nReflect on each one to turn it into a task.',
              icon: Icons.inbox_outlined,
            )
          else
            ...captures.map((cu) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PremiumCard(
                    // Whole card is tappable, not just a small "Reflect" link.
                    onTap: cu.reflected ? null : () => _openReflectionSheet(context, cu),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('${cu.category} — ${cu.tower} ${cu.floor}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                            if (cu.reflected)
                              const StatusChip(label: 'Converted to Task', color: AppColors.success)
                            else
                              const StatusChip(label: 'Needs Reflection', color: AppColors.accentAmber),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('"${cu.transcript}"',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            SeverityChip(severity: cu.severity),
                            StatusChip(label: cu.trade, color: AppColors.info),
                          ],
                        ),
                        if (!cu.reflected) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: const [
                              Icon(Icons.touch_app_rounded, size: 14, color: AppColors.accentTeal),
                              SizedBox(width: 6),
                              Text('Tap to reflect & convert to task',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.accentTeal, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                )),
          const SectionHeader(
            title: 'Photo Proof',
            subtitle: 'Attach site photos, QA/QC evidence, safety observations',
          ),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Take Photo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('From Gallery'),
                      ),
                    ),
                  ],
                ),
                if (_sessionPhotos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sessionPhotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_sessionPhotos[i],
                            width: 84, height: 84, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SectionHeader(
            title: 'Site Checklist',
            subtitle: 'QA checkpoints, safety & punch-list completion',
          ),
          PremiumCard(
            child: Column(
              children: _checklist
                  .map((item) => CheckboxListTile(
                        value: item.checked,
                        onChanged: (v) => setState(() => item.checked = v ?? false),
                        title: Text(item.label, style: const TextStyle(fontSize: 13.5)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.accentTeal,
                        dense: true,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem {
  final String label;
  bool checked;
  _ChecklistItem(this.label, {this.checked = false});
}

/// The core voice capture flow — records → transcribes → AI-structures a
/// RAW capture, then saves it to the "Captured Updates" log below. It no
/// longer creates a task directly; that only happens after the user
/// explicitly reflects on it (see _ReflectionSheet).
class _VoiceCaptureCard extends StatefulWidget {
  const _VoiceCaptureCard();

  @override
  State<_VoiceCaptureCard> createState() => _VoiceCaptureCardState();
}

enum _CaptureStage { idle, recording, transcribing, structured }

class _VoiceCaptureCardState extends State<_VoiceCaptureCard>
    with SingleTickerProviderStateMixin {
  _CaptureStage _stage = _CaptureStage.idle;
  DemoTranscript? _chosenDemo;
  int _selectedDemoIndex = 0;
  String _liveTranscript = '';
  Timer? _timer;
  int _recordSeconds = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _stage = _CaptureStage.recording;
      _recordSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _recordSeconds++);
      if (_recordSeconds >= 3) {
        t.cancel();
        _finishRecording();
      }
    });
  }

  void _finishRecording() {
    final demo = demoTranscripts[_selectedDemoIndex];
    _chosenDemo = demo;
    setState(() {
      _stage = _CaptureStage.transcribing;
      _liveTranscript = '';
    });
    _typewriter(demo.text);
  }

  void _typewriter(String fullText) {
    int i = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (i >= fullText.length) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _stage = _CaptureStage.structured);
        });
        return;
      }
      setState(() => _liveTranscript = fullText.substring(0, i + 1));
      i++;
    });
  }

  void _reset() {
    setState(() {
      _stage = _CaptureStage.idle;
      _chosenDemo = null;
      _liveTranscript = '';
    });
  }

  void _saveCapture() {
    final appState = context.read<AppState>();
    appState.saveCapturedUpdate(_chosenDemo!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to Captured Updates — reflect on it below to create a task.'),
        backgroundColor: AppColors.success,
      ),
    );
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PremiumCard(
        gradientColors: const [Color(0xFF1B2550), Color(0xFF232E52)],
        padding: const EdgeInsets.all(18),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: _buildStageContent(),
        ),
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case _CaptureStage.idle:
        return Column(
          key: const ValueKey('idle'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, color: AppColors.accentTeal, size: 20),
                SizedBox(width: 8),
                Text('Voice-based Site Update',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap and speak naturally — e.g. "Steel not delivered for Tower B, '
              '5th floor." AI will structure it for you to review.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text('Demo scenario to speak',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(demoTranscripts.length, (i) {
                final d = demoTranscripts[i];
                final selected = i == _selectedDemoIndex;
                return ChoiceChip(
                  label: Text(d.category, style: const TextStyle(fontSize: 11.5)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedDemoIndex = i),
                  selectedColor: AppColors.accentTeal.withOpacity(0.3),
                  backgroundColor: AppColors.bgDeep,
                  side: BorderSide(
                    color: selected ? AppColors.accentTeal : Colors.white.withOpacity(0.08),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: _startRecording,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.accentTeal]),
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 34),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text('Record Update',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ),
          ],
        );
      case _CaptureStage.recording:
        return Column(
          key: const ValueKey('recording'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.danger.withOpacity(0.4 + 0.5 * _pulseController.value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Listening…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                Text('0:0${_recordSeconds.clamp(0, 9)}', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(18, (i) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      final h = 8.0 + (24 * ((i % 4 + 1) / 4) * (0.4 + 0.6 * _pulseController.value));
                      return Container(
                        width: 4,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentTeal.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        );
      case _CaptureStage.transcribing:
        return Column(
          key: const ValueKey('transcribing'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.graphic_eq_rounded, color: AppColors.accentTeal, size: 18),
                SizedBox(width: 8),
                Text('Transcribing…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(12)),
              child: Text(
                _liveTranscript.isEmpty ? ' ' : '"$_liveTranscript"',
                style: const TextStyle(fontSize: 13.5, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        );
      case _CaptureStage.structured:
        final d = _chosenDemo!;
        return Column(
          key: const ValueKey('structured'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber, size: 18),
                SizedBox(width: 8),
                Text('AI Structured Update', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(10)),
              child: Text('"${d.text}"',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(label: d.category, color: AppColors.primary),
                StatusChip(label: d.trade, color: AppColors.info),
                StatusChip(label: '${d.tower} · ${d.floor}', color: AppColors.accentTeal),
                SeverityChip(severity: d.severity),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentAmber.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline_rounded, size: 15, color: AppColors.accentAmber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is saved as a raw capture — you\'ll set owner, priority, due date '
                      'and status in a quick reflection step before it becomes a task.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: _reset, child: const Text('Discard')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveCapture,
                    icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                    label: const Text('Save Capture'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

/// The "reflect on a raw capture and convert it into a task" screen.
/// This is the deliberate reflection step: the user reviews what was
/// captured and explicitly sets owner, priority, due date and status.
class _ReflectionSheet extends StatefulWidget {
  final CapturedUpdate capturedUpdate;
  const _ReflectionSheet({required this.capturedUpdate});

  @override
  State<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<_ReflectionSheet> {
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _notesCtrl;
  late String _priority;
  late String _status;
  late DateTime _dueDate;

  static const priorities = ['Low', 'Medium', 'High', 'Urgent'];
  static const statuses = ['Open', 'In Progress', 'Blocked'];

  @override
  void initState() {
    super.initState();
    final cu = widget.capturedUpdate;
    _ownerCtrl = TextEditingController(text: cu.suggestedOwner);
    _notesCtrl = TextEditingController();
    _priority = defaultPriorityForSeverity(cu.severity);
    _status = (cu.severity == 'Critical' || cu.severity == 'High') ? 'Blocked' : 'Open';
    _dueDate = cu.suggestedDueDate;
  }

  @override
  void dispose() {
    _ownerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _convert() {
    if (_ownerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set an owner before converting to a task.')),
      );
      return;
    }
    final appState = context.read<AppState>();
    final task = appState.reflectAndConvert(
      capturedUpdateId: widget.capturedUpdate.id,
      owner: _ownerCtrl.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      status: _status,
      notes: _notesCtrl.text,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task created: "${task.title}"'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cu = widget.capturedUpdate;
    final df = DateFormat('EEE, MMM d');
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
            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber, size: 18),
                SizedBox(width: 8),
                Text('Reflect & Convert to Task', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(10)),
              child: Text('"${cu.transcript}"',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatusChip(label: '${cu.tower} · ${cu.floor}', color: AppColors.accentTeal),
                StatusChip(label: cu.trade, color: AppColors.info),
                SeverityChip(severity: cu.severity),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ownerCtrl,
              decoration: const InputDecoration(labelText: 'Owner', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            const Text('Priority', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: priorities.map((p) {
                final selected = p == _priority;
                return ChoiceChip(
                  label: Text(p, style: const TextStyle(fontSize: 12.5)),
                  selected: selected,
                  onSelected: (_) => setState(() => _priority = p),
                  selectedColor: priorityColor(p).withOpacity(0.35),
                  backgroundColor: AppColors.surfaceLight,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: statuses.map((s) {
                final selected = s == _status;
                return ChoiceChip(
                  label: Text(s, style: const TextStyle(fontSize: 12.5)),
                  selected: selected,
                  onSelected: (_) => setState(() => _status = s),
                  selectedColor: statusColor(s).withOpacity(0.35),
                  backgroundColor: AppColors.surfaceLight,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Due date', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Material(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 18, color: AppColors.accentTeal),
                      const SizedBox(width: 10),
                      Text(df.format(_dueDate), style: const TextStyle(fontSize: 13.5)),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reflection notes (optional)',
                hintText: 'Any additional context before this becomes a task…',
                alignLabelWithHint: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _convert,
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Convert to Task'),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

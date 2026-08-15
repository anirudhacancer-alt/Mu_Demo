import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _VoiceCaptureCard(),
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

/// The core voice → AI structuring → task creation flow.
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

  final _titleCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  late String _severity;
  late String _category;

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
    _titleCtrl.dispose();
    _ownerCtrl.dispose();
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
        _runAiStructuring();
        return;
      }
      setState(() => _liveTranscript = fullText.substring(0, i + 1));
      i++;
    });
  }

  void _runAiStructuring() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _chosenDemo == null) return;
      final d = _chosenDemo!;
      _titleCtrl.text = '${d.category} — ${d.tower} ${d.floor}';
      _ownerCtrl.text = d.suggestedOwner;
      _severity = d.severity;
      _category = d.category;
      setState(() => _stage = _CaptureStage.structured);
    });
  }

  void _reset() {
    setState(() {
      _stage = _CaptureStage.idle;
      _chosenDemo = null;
      _liveTranscript = '';
    });
  }

  void _createTask() {
    final appState = context.read<AppState>();
    final d = _chosenDemo!;
    final update = VoiceUpdate(
      id: 'live',
      transcript: d.text,
      category: _category,
      trade: d.trade,
      tower: d.tower,
      floor: d.floor,
      vendor: d.vendor,
      severity: _severity,
      suggestedOwner: _ownerCtrl.text,
      suggestedDueDate: DateTime.now().add(Duration(days: d.dueInDays)),
    );
    appState.voiceUpdates.insert(0, update);
    final task = appState.createTaskFromVoiceUpdate(update);
    task.title = _titleCtrl.text;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task created: "${task.title}" · owner ${task.owner}'),
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
              '5th floor." AI will structure it into a task automatically.',
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
                      color: AppColors.danger
                          .withOpacity(0.4 + 0.5 * _pulseController.value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Listening…',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                Text('0:0${_recordSeconds.clamp(0, 9)}',
                    style: const TextStyle(color: AppColors.textSecondary)),
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
                      final h = 8.0 +
                          (24 *
                              ((i % 4 + 1) / 4) *
                              (0.4 + 0.6 * _pulseController.value));
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
                Text('Transcribing…',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _liveTranscript.isEmpty ? ' ' : '"$_liveTranscript"',
                style: const TextStyle(
                    fontSize: 13.5, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        );
      case _CaptureStage.structured:
        return _buildStructuredForm();
    }
    // Unreachable: switch above is exhaustive over _CaptureStage, kept as a
    // defensive fallback so the analyzer never flags a missing return.
    // ignore: dead_code
    return const SizedBox.shrink();
  }

  Widget _buildStructuredForm() {
    final d = _chosenDemo!;
    return Column(
      key: const ValueKey('structured'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber, size: 18),
            SizedBox(width: 8),
            Text('AI Structured Update',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bgDeep,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('"${d.text}"',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(label: _category, color: AppColors.primary),
            StatusChip(label: d.trade, color: AppColors.info),
            StatusChip(label: '${d.tower} · ${d.floor}', color: AppColors.accentTeal),
            SeverityChip(severity: _severity),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Task title'),
          style: const TextStyle(fontSize: 13.5),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ownerCtrl,
          decoration: const InputDecoration(labelText: 'Suggested owner'),
          style: const TextStyle(fontSize: 13.5),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _reset,
                child: const Text('Discard'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _createTask,
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Create Task'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

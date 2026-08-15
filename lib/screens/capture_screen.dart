import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

IconData _iconForSourceType(String sourceType) {
  switch (sourceType) {
    case 'Voice (Demo)':
    case 'Voice (Recorded)':
      return Icons.mic_rounded;
    case 'Video Report':
      return Icons.videocam_rounded;
    case 'Photo & Video Report':
      return Icons.perm_media_rounded;
    case 'Manual Report':
      return Icons.edit_note_rounded;
    default:
      return Icons.photo_camera_rounded;
  }
}

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final List<_ChecklistItem> _checklist = [
    _ChecklistItem('Safety helmets & PPE worn on site'),
    _ChecklistItem('Housekeeping — debris cleared from work zone'),
    _ChecklistItem('Scaffolding & guard rails secured'),
    _ChecklistItem('QA checkpoints signed off before pour/finish'),
  ];

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
          if (appState.firebaseEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: const [
                  Icon(Icons.cloud_done_rounded, size: 14, color: AppColors.success),
                  SizedBox(width: 6),
                  Text('Firebase connected — captures sync automatically',
                      style: TextStyle(fontSize: 11.5, color: AppColors.success)),
                ],
              ),
            ),
          const _VoiceCaptureCard(),
          const SizedBox(height: 14),
          const _RealVoiceCaptureCard(),
          const SizedBox(height: 14),
          const _PhotoVideoCaptureCard(),
          SectionHeader(
            title: 'Captured Updates',
            subtitle: captures.isEmpty
                ? 'Nothing captured yet — record or report an update above'
                : '${appState.pendingReflectionCount} awaiting reflection · tap any card to convert',
          ),
          if (captures.isEmpty)
            const EmptyState(
              message: 'Captures from voice, photo, or video land here first.\nReflect on each one to turn it into a task.',
              icon: Icons.inbox_outlined,
            )
          else
            ...captures.map((cu) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PremiumCard(
                    onTap: cu.reflected ? null : () => _openReflectionSheet(context, cu),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_iconForSourceType(cu.sourceType), size: 16, color: AppColors.accentTeal),
                            const SizedBox(width: 8),
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
                            StatusChip(label: cu.sourceType, color: AppColors.info),
                            if (cu.photos.isNotEmpty)
                              StatusChip(label: '${cu.photos.length} photo(s)', color: AppColors.primary),
                            if (cu.videoFile != null)
                              const StatusChip(label: 'Video attached', color: AppColors.primary),
                            if (cu.audioFile != null)
                              const StatusChip(label: 'Audio attached', color: AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (!cu.reflected)
                              Expanded(
                                child: Row(
                                  children: const [
                                    Icon(Icons.touch_app_rounded, size: 14, color: AppColors.accentTeal),
                                    SizedBox(width: 6),
                                    Text('Tap to reflect & convert to task',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.accentTeal, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )
                            else
                              const Spacer(),
                            CloudSyncBadge(status: cu.cloudSyncStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
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

/// ============================================================================
/// CARD 1: Demo voice scenario capture (unchanged reliable stage-demo path).
/// ============================================================================
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
    return PremiumCard(
      gradientColors: const [Color(0xFF1B2550), Color(0xFF232E52)],
      padding: const EdgeInsets.all(18),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: _buildStageContent(),
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
                Text('Voice Update — Demo Scenario',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Reliable, presenter-controlled scenarios for the stage demo — '
              'pick one, tap the mic, and AI structures it for you to review.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
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
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _startRecording,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.accentTeal]),
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                ),
              ),
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
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _reset, child: const Text('Discard'))),
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

/// ============================================================================
/// CARD 2: REAL microphone recording -> audio file + typed caption -> capture.
/// ============================================================================
class _RealVoiceCaptureCard extends StatefulWidget {
  const _RealVoiceCaptureCard();

  @override
  State<_RealVoiceCaptureCard> createState() => _RealVoiceCaptureCardState();
}

enum _RealVoiceStage { idle, recording, review }

class _RealVoiceCaptureCardState extends State<_RealVoiceCaptureCard>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  _RealVoiceStage _stage = _RealVoiceStage.idle;
  Timer? _timer;
  int _seconds = 0;
  File? _audioFile;
  late AnimationController _pulseController;

  final _captionCtrl = TextEditingController();
  final _towerCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  String _severity = 'Medium';
  static const severities = ['Low', 'Medium', 'High', 'Critical'];

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
    _captionCtrl.dispose();
    _towerCtrl.dispose();
    _floorCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied.')),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/v2e_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      setState(() {
        _stage = _RealVoiceStage.recording;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start recording on this device.')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final path = await _recorder.stop();
      setState(() {
        _stage = _RealVoiceStage.review;
        _audioFile = path != null ? File(path) : null;
      });
    } catch (e) {
      setState(() => _stage = _RealVoiceStage.idle);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording could not be saved.')),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _stage = _RealVoiceStage.idle;
      _audioFile = null;
      _seconds = 0;
      _captionCtrl.clear();
      _towerCtrl.clear();
      _floorCtrl.clear();
      _severity = 'Medium';
    });
  }

  void _saveCapture() {
    if (_captionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type a short caption describing the issue.')),
      );
      return;
    }
    context.read<AppState>().saveManualCapture(
          sourceType: 'Voice (Recorded)',
          description: _captionCtrl.text.trim(),
          tower: _towerCtrl.text,
          floor: _floorCtrl.text,
          severity: _severity,
          audioFile: _audioFile,
        );
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
    return PremiumCard(
      gradientColors: const [Color(0xFF17203E), Color(0xFF1E2A55)],
      padding: const EdgeInsets.all(18),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_stage) {
      case _RealVoiceStage.idle:
        return Column(
          key: const ValueKey('rv-idle'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.record_voice_over_rounded, color: AppColors.accentAmber, size: 20),
                SizedBox(width: 8),
                Text('Record Real Voice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Records your actual voice to an audio file. You\'ll add a short '
              'typed caption afterward (live speech-to-text isn\'t used here, '
              'to keep this 100% reliable on any device).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _startRecording,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.accentAmber, AppColors.accentCoral]),
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        );
      case _RealVoiceStage.recording:
        return Column(
          key: const ValueKey('rv-recording'),
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
                const Text('Recording…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                Text(_fmtSeconds(_seconds), style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _stopRecording,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.danger,
                  ),
                  child: const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        );
      case _RealVoiceStage.review:
        return Column(
          key: const ValueKey('rv-review'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Text('Recording saved (${_fmtSeconds(_seconds)})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _captionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Caption — what did you report?',
                hintText: 'e.g. Steel not delivered for Tower B, 5th floor',
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _towerCtrl,
                    decoration: const InputDecoration(labelText: 'Tower (optional)'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _floorCtrl,
                    decoration: const InputDecoration(labelText: 'Floor (optional)'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Severity', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: severities.map((s) {
                final selected = s == _severity;
                return ChoiceChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _severity = s),
                  selectedColor: severityColor(s).withOpacity(0.35),
                  backgroundColor: AppColors.bgDeep,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _reset, child: const Text('Discard'))),
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

  String _fmtSeconds(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }
}

/// ============================================================================
/// CARD 3: Photo / Video report — camera captures + required text field ->
/// capture (per the request: "photo and video with a text field... used to
/// create a task").
/// ============================================================================
class _PhotoVideoCaptureCard extends StatefulWidget {
  const _PhotoVideoCaptureCard();

  @override
  State<_PhotoVideoCaptureCard> createState() => _PhotoVideoCaptureCardState();
}

class _PhotoVideoCaptureCardState extends State<_PhotoVideoCaptureCard> {
  final List<File> _photos = [];
  File? _video;
  final _descCtrl = TextEditingController();
  final _towerCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  String _severity = 'Medium';
  static const severities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _descCtrl.dispose();
    _towerCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (file != null) setState(() => _photos.add(File(file.path)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not available on this device.')),
        );
      }
    }
  }

  Future<void> _recordVideo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );
      if (file != null) setState(() => _video = File(file.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not available on this device.')),
        );
      }
    }
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));
  void _removeVideo() => setState(() => _video = null);

  void _saveCapture() {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue before saving.')),
      );
      return;
    }
    String sourceType;
    if (_photos.isNotEmpty && _video != null) {
      sourceType = 'Photo & Video Report';
    } else if (_photos.isNotEmpty) {
      sourceType = 'Photo Report';
    } else if (_video != null) {
      sourceType = 'Video Report';
    } else {
      sourceType = 'Manual Report';
    }
    context.read<AppState>().saveManualCapture(
          sourceType: sourceType,
          description: _descCtrl.text.trim(),
          tower: _towerCtrl.text,
          floor: _floorCtrl.text,
          severity: _severity,
          photos: _photos.isEmpty ? null : List<File>.from(_photos),
          videoFile: _video,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to Captured Updates — reflect on it below to create a task.'),
        backgroundColor: AppColors.success,
      ),
    );
    setState(() {
      _photos.clear();
      _video = null;
      _descCtrl.clear();
      _towerCtrl.clear();
      _floorCtrl.clear();
      _severity = 'Medium';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      gradientColors: const [Color(0xFF14213D), Color(0xFF1B2C52)],
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.camera_alt_rounded, color: AppColors.accentTeal, size: 20),
              SizedBox(width: 8),
              Text('Photo / Video Report', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Take a photo or record a short video of the issue, describe it '
            'below, and save — it becomes a task once you reflect on it.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text('Take Photo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _recordVideo,
                  icon: const Icon(Icons.videocam_rounded, size: 18),
                  label: const Text('Record Video'),
                ),
              ),
            ],
          ),
          if (_photos.isNotEmpty || _video != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._photos.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(e.value, width: 84, height: 84, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removePhoto(e.key),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (_video != null)
                    Stack(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.bgDeep,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.videocam_rounded, color: AppColors.accentTeal, size: 28),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: _removeVideo,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Describe the issue',
              hintText: 'e.g. Waterproofing gap found on Tower B terrace',
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _towerCtrl,
                  decoration: const InputDecoration(labelText: 'Tower (optional)'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _floorCtrl,
                  decoration: const InputDecoration(labelText: 'Floor (optional)'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Severity', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: severities.map((s) {
              final selected = s == _severity;
              return ChoiceChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_) => setState(() => _severity = s),
                selectedColor: severityColor(s).withOpacity(0.35),
                backgroundColor: AppColors.bgDeep,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveCapture,
              icon: const Icon(Icons.bookmark_add_rounded, size: 18),
              label: const Text('Save Capture'),
            ),
          ),
        ],
      ),
    );
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
    _ownerCtrl = TextEditingController(text: cu.suggestedOwner == 'Unassigned' ? '' : cu.suggestedOwner);
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
              children: [
                Icon(_iconForSourceType(cu.sourceType), color: AppColors.accentAmber, size: 18),
                const SizedBox(width: 8),
                const Text('Reflect & Convert to Task', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
            if (cu.hasMedia) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (cu.photos.isNotEmpty)
                    StatusChip(label: '${cu.photos.length} photo(s) attached', color: AppColors.primary),
                  if (cu.videoFile != null)
                    const StatusChip(label: 'Video attached', color: AppColors.primary),
                  if (cu.audioFile != null)
                    const StatusChip(label: 'Audio attached', color: AppColors.primary),
                ],
              ),
            ],
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

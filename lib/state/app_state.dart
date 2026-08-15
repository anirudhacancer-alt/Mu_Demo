import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../data/demo_accounts.dart';
import '../services/firebase_bridge.dart';

class AppState extends ChangeNotifier {
  UserRole? currentRole;
  String userName = 'Anirudha';

  /// Set true right after a (real or demo-switch) login, so the home
  /// screen can show a one-time "Logged in as X" confirmation, then reset
  /// to false. Satisfies the "role identification after login" requirement.
  bool justLoggedIn = false;

  bool get firebaseEnabled => FirebaseBridge.available;

  final List<SiteTask> tasks = MockData.seedTasks();
  final List<ProcurementItem> procurementItems = MockData.seedProcurement();
  final List<SnagItem> snags = MockData.seedSnags();
  final List<StandupEntry> standups = MockData.seedStandups();
  final SprintModel sprint = MockData.seedSprint();
  final List<RiskAlert> baseRisks = MockData.seedRisks();

  /// Raw captures awaiting reflection (capture-to-task staging area).
  final List<CapturedUpdate> capturedUpdates = [];

  int _idCounter = 100;
  String _nextId(String prefix) => '$prefix${_idCounter++}';

  AppState() {
    // Best-effort: mirror the local demo credential list into Firestore
    // once, if Firebase happens to already be configured/reachable. Never
    // blocks or awaits — purely a background nicety.
    FirebaseBridge.seedAccountsIfNeeded(demoAccounts.map((a) => a.toMap()).toList());
  }

  void login(UserRole role, {String? username}) {
    currentRole = role;
    if (username != null && username.trim().isNotEmpty) {
      userName = username.trim();
    }
    justLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    currentRole = null;
    notifyListeners();
  }

  // ---------------- Capture → Reflection → Task ----------------

  /// Step 1 (demo voice scenario): save a raw capture WITHOUT creating a
  /// task yet. It sits in `capturedUpdates` pending reflection.
  CapturedUpdate saveCapturedUpdate(DemoTranscript demo) {
    final cu = CapturedUpdate(
      id: _nextId('cu'),
      sourceType: 'Voice (Demo)',
      transcript: demo.text,
      category: demo.category,
      trade: demo.trade,
      tower: demo.tower,
      floor: demo.floor,
      vendor: demo.vendor,
      severity: demo.severity,
      suggestedOwner: demo.suggestedOwner,
      suggestedDueDate: DateTime.now().add(Duration(days: demo.dueInDays)),
    );
    capturedUpdates.insert(0, cu);
    notifyListeners();
    _syncCapturedUpdate(cu);
    return cu;
  }

  /// Step 1 (real capture): used by BOTH the real-voice-recording card and
  /// the photo/video report card. Creates a raw capture from
  /// user-typed text + optional attached media, pending reflection.
  CapturedUpdate saveManualCapture({
    required String sourceType,
    required String description,
    required String tower,
    required String floor,
    required String severity,
    List<File>? photos,
    File? videoFile,
    File? audioFile,
  }) {
    final cu = CapturedUpdate(
      id: _nextId('cu'),
      sourceType: sourceType,
      transcript: description,
      category: sourceType,
      trade: 'General',
      tower: tower.trim().isEmpty ? 'Unspecified' : tower.trim(),
      floor: floor.trim().isEmpty ? 'Unspecified' : floor.trim(),
      vendor: 'N/A',
      severity: severity,
      suggestedOwner: 'Unassigned',
      suggestedDueDate: DateTime.now().add(const Duration(days: 2)),
      photos: photos,
      videoFile: videoFile,
      audioFile: audioFile,
    );
    capturedUpdates.insert(0, cu);
    notifyListeners();
    _syncCapturedUpdate(cu);
    return cu;
  }

  /// Step 2: user reflects on a raw capture and explicitly converts it
  /// into an actionable SiteTask with owner/priority/due date/status.
  SiteTask reflectAndConvert({
    required String capturedUpdateId,
    required String owner,
    required String priority,
    required DateTime dueDate,
    required String status,
    String? notes,
  }) {
    final cu = capturedUpdates.firstWhere((c) => c.id == capturedUpdateId);
    final description = (notes != null && notes.trim().isNotEmpty)
        ? '${cu.transcript}\n\nReflection notes: ${notes.trim()}'
        : cu.transcript;
    final task = SiteTask(
      id: _nextId('t'),
      title: '${cu.category} — ${cu.tower} ${cu.floor}',
      description: description,
      tower: cu.tower,
      floor: cu.floor,
      trade: cu.trade,
      vendor: cu.vendor,
      severity: cu.severity,
      priority: priority,
      status: status,
      owner: owner,
      dueDate: dueDate,
      isBlocker: status == 'Blocked',
      photos: cu.photos,
      videoFile: cu.videoFile,
      audioFile: cu.audioFile,
      sourceTranscript: cu.transcript,
      sourceCapturedUpdateId: cu.id,
    );
    tasks.insert(0, task);
    cu.reflected = true;
    cu.linkedTaskId = task.id;
    notifyListeners();
    _syncTask(task);
    return task;
  }

  int get pendingReflectionCount =>
      capturedUpdates.where((c) => !c.reflected).length;

  void addManualTask(SiteTask task) {
    tasks.insert(0, task);
    notifyListeners();
    _syncTask(task);
  }

  void updateTaskStatus(String id, String status) {
    final t = tasks.firstWhere((e) => e.id == id);
    t.status = status;
    notifyListeners();
    // Keep the cloud record in sync too — this is what makes a "closed"
    // (Resolved) status durable in Firestore, not just in local memory.
    FirebaseBridge.updateTaskFields(t.id, {'status': status});
  }

  void updateTaskPriority(String id, String priority) {
    final t = tasks.firstWhere((e) => e.id == id);
    t.priority = priority;
    notifyListeners();
    FirebaseBridge.updateTaskFields(t.id, {'priority': priority});
  }

  // ---------------- Tasks / Blockers ----------------
  List<SiteTask> get blockers => tasks.where((t) => t.isBlocker && t.status != 'Resolved').toList();

  double get avgBlockerAgingDays {
    final open = blockers;
    if (open.isEmpty) return 0;
    return open.fold<int>(0, (a, b) => a + b.agingDays) / open.length;
  }

  int get criticalDelaysCount =>
      tasks.where((t) => t.severity == 'Critical' && t.status != 'Resolved').length;

  double get plannedVsDonePercent {
    if (standups.isEmpty) return 0;
    return standups.first.plannedVsDonePercent;
  }

  // ---------------- Procurement ----------------
  void updateProcurementStatus(String id, String status) {
    final p = procurementItems.firstWhere((e) => e.id == id);
    p.status = status;
    notifyListeners();
  }

  void addProcurementItem(ProcurementItem item) {
    procurementItems.insert(0, item);
    notifyListeners();
  }

  int get procurementRiskCount =>
      procurementItems.where((p) => p.status == 'Delayed').length;

  // ---------------- QA / Snags ----------------
  void resolveSnag(String id, {String? proof}) {
    final s = snags.firstWhere((e) => e.id == id);
    s.status = 'Resolved';
    s.passFail = true;
    s.resolutionProof = proof ?? 'Marked resolved by site team.';
    notifyListeners();
  }

  void addSnag(SnagItem snag) {
    snags.insert(0, snag);
    notifyListeners();
  }

  int get openSnagsCount => snags.where((s) => s.status == 'Open').length;

  // ---------------- Standup reflection (continuous record) ----------------
  void submitStandup(StandupEntry entry) {
    standups.insert(0, entry);
    notifyListeners();
  }

  StandupEntry newEmptyStandupDraft() => StandupEntry(
        id: _nextId('su'),
        date: DateTime.now(),
        present: 0,
        totalCrew: 0,
        plannedYesterday: [],
        completedYesterday: [],
        blockedItems: [],
        keyLearnings: [],
      );

  // ---------------- Control Tower ----------------
  List<RiskAlert> get riskAlerts {
    final dynamicRisks = <RiskAlert>[];
    for (final b in blockers) {
      if (b.agingDays >= 2) {
        dynamicRisks.add(RiskAlert(
          id: 'dyn-${b.id}',
          title: '${b.title} — aging blocker (${b.agingDays}d)',
          description:
              '${b.trade} blocker at ${b.tower}, ${b.floor} has been open for '
              '${b.agingDays} days. Recommend escalation to ${b.owner}.',
          severity: b.severity,
          source: 'Blocker aging',
        ));
      }
    }
    return [...baseRisks, ...dynamicRisks];
  }

  double get plannedVsDoneOverall {
    final total = tasks.length;
    if (total == 0) return 0;
    final done = tasks.where((t) => t.status == 'Resolved').length;
    return (done / total) * 100;
  }

  String get weeklyReviewSummary {
    final done = tasks.where((t) => t.status == 'Resolved').length;
    final openB = blockers.length;
    final delayed = procurementItems.where((p) => p.status == 'Delayed').length;
    final snagsOpen = openSnagsCount;
    return 'This week: ${tasks.length} tasks tracked, $done resolved, '
        '$openB open blockers (avg aging ${avgBlockerAgingDays.toStringAsFixed(1)}d), '
        '$delayed procurement items delayed, $snagsOpen QA snags open. '
        'Sprint "${sprint.goal.split('.').first}" is ${sprint.progressPercent.toStringAsFixed(0)}% complete '
        'with ${sprint.daysRemaining} day(s) remaining.';
  }

  // ---------------- Firebase background sync (fire-and-forget) ----------------
  // These never block the UI and never throw — AppState/local state remains
  // the single source of truth for rendering. Firebase is a resilient bonus
  // layer: if it's not configured or the device is offline, these simply
  // no-op and the app behaves exactly as it did before Firebase existed.

  Future<void> _syncCapturedUpdate(CapturedUpdate cu) async {
    if (!firebaseEnabled) return;
    cu.cloudSyncStatus = 'syncing';
    notifyListeners();

    String? photoUrl;
    String? videoUrl;
    String? audioUrl;
    try {
      if (cu.photos.isNotEmpty) {
        photoUrl = await FirebaseBridge.uploadFile(
            cu.photos.first, 'captures/${cu.id}/photo.jpg');
      }
      if (cu.videoFile != null) {
        videoUrl = await FirebaseBridge.uploadFile(
            cu.videoFile!, 'captures/${cu.id}/video.mp4');
      }
      if (cu.audioFile != null) {
        audioUrl = await FirebaseBridge.uploadFile(
            cu.audioFile!, 'captures/${cu.id}/audio.m4a');
      }
      final ok = await FirebaseBridge.saveCapturedUpdate(cu.id, {
        'sourceType': cu.sourceType,
        'transcript': cu.transcript,
        'category': cu.category,
        'trade': cu.trade,
        'tower': cu.tower,
        'floor': cu.floor,
        'severity': cu.severity,
        'suggestedOwner': cu.suggestedOwner,
        'createdAt': cu.createdAt.toIso8601String(),
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (audioUrl != null) 'audioUrl': audioUrl,
      });
      cu.cloudSyncStatus = ok ? 'synced' : 'failed';
    } catch (_) {
      cu.cloudSyncStatus = 'failed';
    }
    notifyListeners();
  }

  Future<void> _syncTask(SiteTask task) async {
    if (!firebaseEnabled) return;
    task.cloudSyncStatus = 'syncing';
    notifyListeners();

    String? photoUrl;
    String? videoUrl;
    String? audioUrl;
    try {
      if (task.photos.isNotEmpty) {
        photoUrl = await FirebaseBridge.uploadFile(
            task.photos.first, 'tasks/${task.id}/photo.jpg');
      }
      if (task.videoFile != null) {
        videoUrl = await FirebaseBridge.uploadFile(
            task.videoFile!, 'tasks/${task.id}/video.mp4');
      }
      if (task.audioFile != null) {
        audioUrl = await FirebaseBridge.uploadFile(
            task.audioFile!, 'tasks/${task.id}/audio.m4a');
      }
      final ok = await FirebaseBridge.saveTask(task.id, {
        'title': task.title,
        'description': task.description,
        'tower': task.tower,
        'floor': task.floor,
        'trade': task.trade,
        'vendor': task.vendor,
        'severity': task.severity,
        'priority': task.priority,
        'status': task.status,
        'owner': task.owner,
        'dueDate': task.dueDate.toIso8601String(),
        'createdAt': task.createdAt.toIso8601String(),
        'isBlocker': task.isBlocker,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (audioUrl != null) 'audioUrl': audioUrl,
      });
      task.cloudSyncStatus = ok ? 'synced' : 'failed';
    } catch (_) {
      task.cloudSyncStatus = 'failed';
    }
    notifyListeners();
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class AppState extends ChangeNotifier {
  UserRole? currentRole;
  String userName = 'Anirudha';

  /// Set true right after a (real or demo-switch) login, so the home
  /// screen can show a one-time "Logged in as X" confirmation, then reset
  /// to false. Satisfies the "role identification after login" requirement.
  bool justLoggedIn = false;

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

  /// Step 1: save a raw capture (voice/photo/observation) WITHOUT creating
  /// a task yet. It sits in `capturedUpdates` pending reflection.
  CapturedUpdate saveCapturedUpdate(DemoTranscript demo) {
    final cu = CapturedUpdate(
      id: _nextId('cu'),
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
      sourceTranscript: cu.transcript,
      sourceCapturedUpdateId: cu.id,
    );
    tasks.insert(0, task);
    cu.reflected = true;
    cu.linkedTaskId = task.id;
    notifyListeners();
    return task;
  }

  int get pendingReflectionCount =>
      capturedUpdates.where((c) => !c.reflected).length;

  void addManualTask(SiteTask task) {
    tasks.insert(0, task);
    notifyListeners();
  }

  void updateTaskStatus(String id, String status) {
    final t = tasks.firstWhere((e) => e.id == id);
    t.status = status;
    notifyListeners();
  }

  void updateTaskPriority(String id, String priority) {
    final t = tasks.firstWhere((e) => e.id == id);
    t.priority = priority;
    notifyListeners();
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
}

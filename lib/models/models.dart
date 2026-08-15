import 'dart:io';

enum UserRole { supervisor, siteEngineer, projectManager }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.siteEngineer:
        return 'Site Engineer';
      case UserRole.projectManager:
        return 'Project Manager';
    }
  }
}

/// A unified Task / Blocker item.
class SiteTask {
  final String id;
  String title;
  String description;
  String tower;
  String floor;
  String trade;
  String vendor;
  String severity; // Low / Medium / High / Critical
  String status; // Open / In Progress / Blocked / Resolved
  String owner;
  DateTime dueDate;
  final DateTime createdAt;
  bool isBlocker;
  final List<File> photos;
  final String? sourceTranscript;

  SiteTask({
    required this.id,
    required this.title,
    required this.description,
    required this.tower,
    required this.floor,
    required this.trade,
    required this.vendor,
    required this.severity,
    required this.status,
    required this.owner,
    required this.dueDate,
    DateTime? createdAt,
    this.isBlocker = false,
    List<File>? photos,
    this.sourceTranscript,
  })  : createdAt = createdAt ?? DateTime.now(),
        photos = photos ?? [];

  int get agingDays => DateTime.now().difference(createdAt).inDays;
}

class ProcurementItem {
  final String id;
  String material;
  String vendor;
  String status; // Requested / Confirmed / In Transit / Delayed / Delivered
  DateTime requiredBy;
  String linkedActivity;
  String impact;
  String escalationAction;

  ProcurementItem({
    required this.id,
    required this.material,
    required this.vendor,
    required this.status,
    required this.requiredBy,
    required this.linkedActivity,
    required this.impact,
    required this.escalationAction,
  });
}

class SnagItem {
  final String id;
  String title;
  String trade;
  String severity;
  String status; // Open / Resolved
  String assignedTo;
  DateTime dueDate;
  final List<File> photos;
  String? resolutionProof;
  bool passFail; // true = pass

  SnagItem({
    required this.id,
    required this.title,
    required this.trade,
    required this.severity,
    required this.status,
    required this.assignedTo,
    required this.dueDate,
    List<File>? photos,
    this.resolutionProof,
    this.passFail = false,
  }) : photos = photos ?? [];
}

class StandupEntry {
  final DateTime date;
  int present;
  int totalCrew;
  List<String> plannedYesterday;
  List<String> completedYesterday;
  List<String> blockedItems;

  StandupEntry({
    required this.date,
    required this.present,
    required this.totalCrew,
    required this.plannedYesterday,
    required this.completedYesterday,
    required this.blockedItems,
  });

  double get plannedVsDonePercent => plannedYesterday.isEmpty
      ? 0
      : (completedYesterday.length / plannedYesterday.length) * 100;

  String get aiSummary {
    final pct = plannedVsDonePercent.toStringAsFixed(0);
    final blockedText = blockedItems.isEmpty
        ? 'No blockers reported.'
        : 'Blocked: ${blockedItems.join('; ')}.';
    return 'Attendance $present/$totalCrew. Planned vs done: $pct% '
        '(${completedYesterday.length}/${plannedYesterday.length} tasks completed). '
        '$blockedText';
  }
}

class SprintTaskRef {
  final String taskId;
  final String title;
  final int progressPercent;
  final bool atRisk;
  SprintTaskRef({
    required this.taskId,
    required this.title,
    required this.progressPercent,
    this.atRisk = false,
  });
}

class SprintModel {
  String goal;
  DateTime startDate;
  DateTime endDate;
  List<SprintTaskRef> backlog;
  List<SprintTaskRef> currentSprint;
  String? retrospectiveNotes;

  SprintModel({
    required this.goal,
    required this.startDate,
    required this.endDate,
    required this.backlog,
    required this.currentSprint,
    this.retrospectiveNotes,
  });

  double get progressPercent {
    if (currentSprint.isEmpty) return 0;
    final total = currentSprint.fold<int>(0, (a, b) => a + b.progressPercent);
    return total / currentSprint.length;
  }

  List<SprintTaskRef> get atRiskTasks =>
      currentSprint.where((t) => t.atRisk).toList();

  int get daysRemaining =>
      endDate.difference(DateTime.now()).inDays.clamp(0, 999);
}

class VoiceUpdate {
  final String id;
  final String transcript;
  final String category;
  final String trade;
  final String tower;
  final String floor;
  final String vendor;
  final String severity;
  final String suggestedOwner;
  final DateTime suggestedDueDate;
  final DateTime createdAt;

  VoiceUpdate({
    required this.id,
    required this.transcript,
    required this.category,
    required this.trade,
    required this.tower,
    required this.floor,
    required this.vendor,
    required this.severity,
    required this.suggestedOwner,
    required this.suggestedDueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class RiskAlert {
  final String id;
  final String title;
  final String description;
  final String severity;
  final String source; // e.g. "Blocker aging", "Procurement", "QA"

  RiskAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.source,
  });
}

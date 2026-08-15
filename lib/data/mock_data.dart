import '../models/models.dart';

/// Canned "voice update" demo scenarios used to simulate the
/// Speech-to-Text + AI Structuring journey without needing live
/// microphone / cloud AI access during the demo (keeps it 100% reliable
/// offline, on any device, first try).
class DemoTranscript {
  final String text;
  final String category;
  final String trade;
  final String tower;
  final String floor;
  final String vendor;
  final String severity;
  final String suggestedOwner;
  final int dueInDays;

  const DemoTranscript({
    required this.text,
    required this.category,
    required this.trade,
    required this.tower,
    required this.floor,
    required this.vendor,
    required this.severity,
    required this.suggestedOwner,
    required this.dueInDays,
  });
}

const List<DemoTranscript> demoTranscripts = [
  DemoTranscript(
    text: "Steel not delivered for Tower B, fifth floor. Vendor Shah Steel "
        "confirmed dispatch but truck hasn't arrived. Slab casting scheduled "
        "for tomorrow morning is at risk.",
    category: "Material Delay",
    trade: "Structural / RCC",
    tower: "Tower B",
    floor: "5th Floor",
    vendor: "Shah Steel Suppliers",
    severity: "High",
    suggestedOwner: "Procurement Lead",
    dueInDays: 1,
  ),
  DemoTranscript(
    text: "Found a crack near the beam junction on Tower A, third floor, "
        "close to grid line 4. Needs QA inspection before we pour above it.",
    category: "QA / Structural Defect",
    trade: "Civil / QA",
    tower: "Tower A",
    floor: "3rd Floor",
    vendor: "N/A",
    severity: "Critical",
    suggestedOwner: "QA Engineer",
    dueInDays: 1,
  ),
  DemoTranscript(
    text: "Electrical conduit laying on Tower C, second floor is done, "
        "about eighty percent of planned scope for today. Two electricians "
        "left early due to material shortage.",
    category: "Progress Update",
    trade: "Electrical (MEP)",
    tower: "Tower C",
    floor: "2nd Floor",
    vendor: "N/A",
    severity: "Low",
    suggestedOwner: "MEP Site Engineer",
    dueInDays: 2,
  ),
  DemoTranscript(
    text: "Safety issue — scaffolding on the west wing, sixth floor, is "
        "missing guard rails. Please stop work in that zone until fixed.",
    category: "Safety Observation",
    trade: "Safety / Scaffolding",
    tower: "West Wing",
    floor: "6th Floor",
    vendor: "Apex Scaffolds",
    severity: "Critical",
    suggestedOwner: "Safety Officer",
    dueInDays: 1,
  ),
  DemoTranscript(
    text: "Tiling work for Tower B, ground floor lobby is complete and "
        "ready for client walkthrough. Waiting on adhesive curing, two days.",
    category: "Progress Update",
    trade: "Finishing / Tiling",
    tower: "Tower B",
    floor: "Ground Floor",
    vendor: "N/A",
    severity: "Low",
    suggestedOwner: "Finishing Supervisor",
    dueInDays: 3,
  ),
  DemoTranscript(
    text: "Cement delivery from Ambuja delayed by two days, impacting "
        "plastering work on Tower A, fourth floor. Need an alternate vendor "
        "or an escalation to procurement.",
    category: "Material Delay",
    trade: "Civil / Plastering",
    tower: "Tower A",
    floor: "4th Floor",
    vendor: "Ambuja Cement Distributor",
    severity: "Medium",
    suggestedOwner: "Procurement Lead",
    dueInDays: 2,
  ),
];

class MockData {
  static List<SiteTask> seedTasks() {
    final now = DateTime.now();
    return [
      SiteTask(
        id: 't1',
        title: 'Steel delivery delay — Tower B slab casting',
        description:
            'Steel not delivered for Tower B, 5th floor. Slab casting at risk.',
        tower: 'Tower B',
        floor: '5th Floor',
        trade: 'Structural / RCC',
        vendor: 'Shah Steel Suppliers',
        severity: 'High',
        status: 'Blocked',
        owner: 'Procurement Lead',
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 3)),
        isBlocker: true,
      ),
      SiteTask(
        id: 't2',
        title: 'Beam junction crack — QA inspection',
        description: 'Crack near beam junction, Tower A 3rd floor, grid 4.',
        tower: 'Tower A',
        floor: '3rd Floor',
        trade: 'Civil / QA',
        vendor: 'N/A',
        severity: 'Critical',
        status: 'In Progress',
        owner: 'QA Engineer',
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        isBlocker: false,
      ),
      SiteTask(
        id: 't3',
        title: 'Guard rails missing — West Wing scaffolding',
        description: 'Safety stop-work until guard rails installed.',
        tower: 'West Wing',
        floor: '6th Floor',
        trade: 'Safety / Scaffolding',
        vendor: 'Apex Scaffolds',
        severity: 'Critical',
        status: 'Blocked',
        owner: 'Safety Officer',
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 4)),
        isBlocker: true,
      ),
      SiteTask(
        id: 't4',
        title: 'Electrical conduit laying — Tower C 2nd floor',
        description: '80% complete, minor material shortage.',
        tower: 'Tower C',
        floor: '2nd Floor',
        trade: 'Electrical (MEP)',
        vendor: 'N/A',
        severity: 'Low',
        status: 'In Progress',
        owner: 'MEP Site Engineer',
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      SiteTask(
        id: 't5',
        title: 'Cement delivery delayed — Tower A plastering',
        description: 'Ambuja cement delayed 2 days, impacts plastering.',
        tower: 'Tower A',
        floor: '4th Floor',
        trade: 'Civil / Plastering',
        vendor: 'Ambuja Cement Distributor',
        severity: 'Medium',
        status: 'Open',
        owner: 'Procurement Lead',
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now,
        isBlocker: true,
      ),
      SiteTask(
        id: 't6',
        title: 'Lobby tiling — Tower B ground floor',
        description: 'Complete, curing before client walkthrough.',
        tower: 'Tower B',
        floor: 'Ground Floor',
        trade: 'Finishing / Tiling',
        vendor: 'N/A',
        severity: 'Low',
        status: 'Resolved',
        owner: 'Finishing Supervisor',
        dueDate: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  static List<ProcurementItem> seedProcurement() {
    final now = DateTime.now();
    return [
      ProcurementItem(
        id: 'p1',
        material: 'TMT Steel Bars (12mm)',
        vendor: 'Shah Steel Suppliers',
        status: 'Delayed',
        requiredBy: now.add(const Duration(days: 1)),
        linkedActivity: 'Tower B — Slab casting, 5th floor',
        impact: 'Slab casting for Tower B may slip by 2 days',
        escalationAction: 'Escalate to vendor manager; source backup vendor',
      ),
      ProcurementItem(
        id: 'p2',
        material: 'OPC Cement (Ambuja)',
        vendor: 'Ambuja Cement Distributor',
        status: 'In Transit',
        requiredBy: now.add(const Duration(days: 2)),
        linkedActivity: 'Tower A — Plastering, 4th floor',
        impact: 'Plastering may pause if not delivered by tomorrow evening',
        escalationAction: 'Confirm ETA with distributor; arrange local backup',
      ),
      ProcurementItem(
        id: 'p3',
        material: 'Guard rail scaffolding clamps',
        vendor: 'Apex Scaffolds',
        status: 'Confirmed',
        requiredBy: now.add(const Duration(hours: 12)),
        linkedActivity: 'West Wing — Safety compliance, 6th floor',
        impact: 'Zone remains stop-work until installed',
        escalationAction: 'Priority pickup arranged for this evening',
      ),
      ProcurementItem(
        id: 'p4',
        material: 'Ceramic Floor Tiles (600x600)',
        vendor: 'Kajaria Distributors',
        status: 'Delivered',
        requiredBy: now.subtract(const Duration(days: 3)),
        linkedActivity: 'Tower B — Lobby finishing, ground floor',
        impact: 'No impact — delivered on schedule',
        escalationAction: 'None required',
      ),
      ProcurementItem(
        id: 'p5',
        material: 'Electrical Conduits & Junction Boxes',
        vendor: 'Polycab Regional Distributor',
        status: 'Requested',
        requiredBy: now.add(const Duration(days: 3)),
        linkedActivity: 'Tower C — MEP rough-in, 2nd floor',
        impact: 'Low — buffer stock available for 2 more days',
        escalationAction: 'Follow up if not confirmed within 24 hours',
      ),
    ];
  }

  static List<SnagItem> seedSnags() {
    final now = DateTime.now();
    return [
      SnagItem(
        id: 's1',
        title: 'Beam junction crack, grid line 4',
        trade: 'Civil / QA',
        severity: 'Critical',
        status: 'Open',
        assignedTo: 'ABC Construction Co.',
        dueDate: now.add(const Duration(days: 1)),
      ),
      SnagItem(
        id: 's2',
        title: 'Paint touch-up — 3rd floor corridor',
        trade: 'Finishing / Paint',
        severity: 'Low',
        status: 'Open',
        assignedTo: 'Sunrise Painters',
        dueDate: now.add(const Duration(days: 4)),
      ),
      SnagItem(
        id: 's3',
        title: 'Door alignment — Tower A, Unit 302',
        trade: 'Carpentry',
        severity: 'Medium',
        status: 'Resolved',
        assignedTo: 'Woodline Interiors',
        dueDate: now.subtract(const Duration(days: 1)),
        resolutionProof: 'Realigned and re-hinged; passed re-inspection.',
        passFail: true,
      ),
      SnagItem(
        id: 's4',
        title: 'Waterproofing gap — Tower B terrace',
        trade: 'Civil / Waterproofing',
        severity: 'High',
        status: 'Open',
        assignedTo: 'AquaSeal Contractors',
        dueDate: now.add(const Duration(days: 2)),
      ),
    ];
  }

  static List<StandupEntry> seedStandups() {
    final now = DateTime.now();
    return [
      StandupEntry(
        date: now,
        present: 42,
        totalCrew: 48,
        plannedYesterday: [
          'Slab shuttering — Tower B 5th floor',
          'Conduit laying — Tower C 2nd floor',
          'Plastering — Tower A 4th floor',
          'Lobby tiling — Tower B ground floor',
        ],
        completedYesterday: [
          'Conduit laying — Tower C 2nd floor',
          'Lobby tiling — Tower B ground floor',
        ],
        blockedItems: [
          'Slab shuttering blocked — steel delivery delay',
          'Plastering paused — cement in transit',
        ],
      ),
    ];
  }

  static SprintModel seedSprint() {
    final now = DateTime.now();
    return SprintModel(
      goal: 'Complete Tower B structural work up to 5th floor and close all '
          'critical safety snags before the client review.',
      startDate: now.subtract(const Duration(days: 4)),
      endDate: now.add(const Duration(days: 6)),
      backlog: [
        SprintTaskRef(taskId: 'b1', title: 'Waterproofing — Tower B terrace', progressPercent: 0),
        SprintTaskRef(taskId: 'b2', title: 'MEP first fix — Tower A 5th floor', progressPercent: 0),
        SprintTaskRef(taskId: 'b3', title: 'External plastering — Tower C', progressPercent: 0),
      ],
      currentSprint: [
        SprintTaskRef(taskId: 't1', title: 'Steel delivery & slab casting — Tower B', progressPercent: 35, atRisk: true),
        SprintTaskRef(taskId: 't2', title: 'QA fix — beam junction crack', progressPercent: 60, atRisk: true),
        SprintTaskRef(taskId: 't3', title: 'Guard rail install — West Wing', progressPercent: 70),
        SprintTaskRef(taskId: 't4', title: 'Conduit laying — Tower C', progressPercent: 80),
        SprintTaskRef(taskId: 't6', title: 'Lobby tiling — Tower B', progressPercent: 100),
      ],
    );
  }

  static List<RiskAlert> seedRisks() {
    return [
      RiskAlert(
        id: 'r1',
        title: 'Steel delivery delay may impact Tower B slab activity',
        description: 'Shah Steel Suppliers dispatch is 2 days overdue. Slab '
            'casting on Tower B, 5th floor is at risk of slipping by up to '
            '3 days if not resolved by tomorrow evening.',
        severity: 'High',
        source: 'Procurement',
      ),
      RiskAlert(
        id: 'r2',
        title: 'Aging blocker — West Wing safety stop-work',
        description: 'Guard rail blocker has been open for 4 days, the '
            'longest-aging blocker this sprint. Recommend escalating to '
            'safety officer and vendor today.',
        severity: 'Critical',
        source: 'Blocker aging',
      ),
      RiskAlert(
        id: 'r3',
        title: 'Repeated cement delivery delays from Ambuja',
        description: 'This is the second delay from this distributor in 2 '
            'weeks. Consider a backup vendor for plastering-critical towers.',
        severity: 'Medium',
        source: 'Procurement pattern',
      ),
    ];
  }
}

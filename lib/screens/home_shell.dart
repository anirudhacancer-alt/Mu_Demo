import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'capture_screen.dart';
import 'tasks_screen.dart';
import 'daily_execution_screen.dart';
import 'sprint_screen.dart';
import 'procurement_qa_screen.dart';
import 'control_tower_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    // Land the right role on the most relevant module first.
    final role = context.read<AppState>().currentRole;
    _index = role == UserRole.projectManager ? 5 : 2;
  }

  static const _titles = [
    'Capture',
    'Tasks & Blockers',
    'Daily Execution',
    'Sprint',
    'Procurement & QA',
    'Control Tower',
  ];

  final _pages = const [
    CaptureScreen(),
    TasksScreen(),
    DailyExecutionScreen(),
    SprintScreen(),
    ProcurementQaScreen(),
    ControlTowerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: () => _showRoleSwitcher(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 15, color: AppColors.accentTeal),
                      const SizedBox(width: 6),
                      Text(appState.currentRole?.label ?? '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic_rounded), label: 'Capture'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.today_rounded), label: 'Daily'),
          BottomNavigationBarItem(icon: Icon(Icons.view_kanban_rounded), label: 'Sprint'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Procure/QA'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Control'),
        ],
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Switch role',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              ...UserRole.values.map((r) => ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(r.label),
                    onTap: () {
                      context.read<AppState>().login(r);
                      Navigator.pop(ctx);
                    },
                  )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                title: const Text('Log out', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  context.read<AppState>().logout();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

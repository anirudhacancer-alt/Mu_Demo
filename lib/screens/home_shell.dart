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

class _NavTab {
  final String label;
  final IconData icon;
  final Widget screen;
  const _NavTab(this.label, this.icon, this.screen);
}

/// Role-based navigation: each role only sees the tabs relevant to their
/// responsibility and authority. In particular, the Control Tower (manager
/// dashboard) is only ever shown to Project Manager — Supervisors (and
/// Site Engineers) never get it, satisfying the "manager dashboard
/// shouldn't be seen by supervisors" requirement.
List<_NavTab> _tabsForRole(UserRole role) {
  switch (role) {
    case UserRole.supervisor:
      return const [
        _NavTab('Capture', Icons.mic_rounded, CaptureScreen()),
        _NavTab('Tasks', Icons.checklist_rounded, TasksScreen()),
        _NavTab('Daily', Icons.today_rounded, DailyExecutionScreen()),
      ];
    case UserRole.siteEngineer:
      return const [
        _NavTab('Capture', Icons.mic_rounded, CaptureScreen()),
        _NavTab('Tasks', Icons.checklist_rounded, TasksScreen()),
        _NavTab('Sprint', Icons.view_kanban_rounded, SprintScreen()),
        _NavTab('Procure/QA', Icons.inventory_2_rounded, ProcurementQaScreen()),
      ];
    case UserRole.projectManager:
      return const [
        _NavTab('Sprint', Icons.view_kanban_rounded, SprintScreen()),
        _NavTab('Procure/QA', Icons.inventory_2_rounded, ProcurementQaScreen()),
        _NavTab('Control', Icons.dashboard_rounded, ControlTowerScreen()),
      ];
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  UserRole? _lastRole;
  bool _confirmationScheduled = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final role = appState.currentRole!;
    final tabs = _tabsForRole(role);

    // Role changed (e.g. via demo role-switcher) — reset to that role's
    // first tab so we never index into a tab list that no longer exists
    // for the new role.
    if (_lastRole != role) {
      _lastRole = role;
      _index = 0;
    }
    if (_index >= tabs.length) _index = 0;

    if (appState.justLoggedIn && !_confirmationScheduled) {
      _confirmationScheduled = true;
      appState.justLoggedIn = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged in as ${role.label} (${appState.userName})'),
            backgroundColor: AppColors.success,
          ),
        );
        _confirmationScheduled = false;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_index].label),
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
                      Text(role.label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: tabs
            .map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label))
            .toList(),
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
              const Text('Demo: switch role',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                'Presenter shortcut — a real deployment would require signing '
                'out and back in with different credentials.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary.withOpacity(0.8)),
              ),
              const SizedBox(height: 10),
              ...UserRole.values.map((r) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        context.read<AppState>().login(r);
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded),
                            const SizedBox(width: 12),
                            Text(r.label, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  )),
              const Divider(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context.read<AppState>().logout();
                    Navigator.pop(ctx);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.danger),
                        SizedBox(width: 12),
                        Text('Log out', style: TextStyle(color: AppColors.danger, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

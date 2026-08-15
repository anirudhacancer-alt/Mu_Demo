import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDeep, AppColors.bgDeep2, Color(0xFF1B234A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: AppColors.aurora,
                  ).createShader(rect),
                  child: const Text(
                    'V2E',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'SiteVoice.AI — Voice to Execution',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Speak your site update. AI structures it, creates the '
                  'task, and tracks it to closure — no typing required.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Select your role to continue',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  role: UserRole.supervisor,
                  icon: Icons.engineering_rounded,
                  description:
                      'Record site updates, manage blockers, run daily standups.',
                  colors: const [Color(0xFF3E5BDB), Color(0xFF6C8CFF)],
                ),
                const SizedBox(height: 14),
                _RoleCard(
                  role: UserRole.siteEngineer,
                  icon: Icons.architecture_rounded,
                  description:
                      'Track QA snags, procurement, and sprint execution.',
                  colors: const [Color(0xFF0F766E), Color(0xFF2DD4BF)],
                ),
                const SizedBox(height: 14),
                _RoleCard(
                  role: UserRole.projectManager,
                  icon: Icons.dashboard_rounded,
                  description:
                      'Monitor risks, escalations, and the weekly review pack.',
                  colors: const [Color(0xFFB45309), Color(0xFFFBBF24)],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'V2E Prototype · Demo Build',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary.withOpacity(0.6)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String description;
  final List<Color> colors;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.description,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<AppState>().login(role),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(description,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12.5,
                            height: 1.3)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

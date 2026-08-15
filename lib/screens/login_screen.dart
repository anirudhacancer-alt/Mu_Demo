import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/demo_accounts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole? _selectedRole;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _showDemoCreds = false;
  String? _errorText;
  bool _submitting = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
      _errorText = null;
    });
  }

  Future<void> _signIn() async {
    if (_selectedRole == null) return;
    final result = validateLogin(
      username: _usernameCtrl.text,
      password: _passwordCtrl.text,
      selectedRole: _selectedRole!,
    );
    if (!result.success) {
      setState(() => _errorText = loginErrorMessage(result.error));
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    // Small delay purely for a realistic "signing in" feel in the demo.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.read<AppState>().login(_selectedRole!, username: result.account!.username);
  }

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
                const SizedBox(height: 10),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: AppColors.aurora,
                  ).createShader(rect),
                  child: const Text(
                    'V2E',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'SiteVoice.AI — Voice to Execution',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  '1. Select your role',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  role: UserRole.supervisor,
                  icon: Icons.engineering_rounded,
                  description: 'Record site updates, manage blockers, run daily standups.',
                  colors: const [Color(0xFF3E5BDB), Color(0xFF6C8CFF)],
                  selected: _selectedRole == UserRole.supervisor,
                  onTap: () => _selectRole(UserRole.supervisor),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  role: UserRole.siteEngineer,
                  icon: Icons.architecture_rounded,
                  description: 'Track QA snags, procurement, and sprint execution.',
                  colors: const [Color(0xFF0F766E), Color(0xFF2DD4BF)],
                  selected: _selectedRole == UserRole.siteEngineer,
                  onTap: () => _selectRole(UserRole.siteEngineer),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  role: UserRole.projectManager,
                  icon: Icons.dashboard_rounded,
                  description: 'Monitor risks, escalations, and the weekly review pack.',
                  colors: const [Color(0xFFB45309), Color(0xFFFBBF24)],
                  selected: _selectedRole == UserRole.projectManager,
                  onTap: () => _selectRole(UserRole.projectManager),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: _selectedRole == null
                      ? const SizedBox(width: double.infinity, height: 0)
                      : Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: _CredentialForm(
                            role: _selectedRole!,
                            usernameCtrl: _usernameCtrl,
                            passwordCtrl: _passwordCtrl,
                            obscurePassword: _obscurePassword,
                            onToggleObscure: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            errorText: _errorText,
                            submitting: _submitting,
                            onSubmit: _signIn,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showDemoCreds = !_showDemoCreds),
                    icon: Icon(
                      _showDemoCreds ? Icons.visibility_off_rounded : Icons.info_outline_rounded,
                      size: 16,
                    ),
                    label: Text(_showDemoCreds ? 'Hide demo credentials' : 'Show demo credentials'),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _showDemoCreds
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: demoAccounts
                                .map((a) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Text(
                                        '${a.role.label}:  ${a.username} / ${a.password}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ))
                                .toList(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'V2E Prototype · Demo Build',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary.withOpacity(0.6)),
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
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.description,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? Border.all(color: Colors.white, width: 2.5)
                : Border.all(color: Colors.transparent, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(selected ? 0.5 : 0.3),
                blurRadius: selected ? 22 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.label,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: selected ? 22 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialForm extends StatelessWidget {
  final UserRole role;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final String? errorText;
  final bool submitting;
  final VoidCallback onSubmit;

  const _CredentialForm({
    required this.role,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.errorText,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Sign in as ${role.label}',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
            style: const TextStyle(fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordCtrl,
            obscureText: obscurePassword,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            style: const TextStyle(fontSize: 13.5),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(errorText!,
                        style: const TextStyle(fontSize: 12, color: AppColors.danger, height: 1.3)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login_rounded, size: 18),
              label: Text(submitting ? 'Signing in…' : 'Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}

import '../models/models.dart';

/// Mock local credentials for the demo build. Validation happens
/// synchronously against this fixed list (zero network dependency, so login
/// always works instantly even offline) — the same list is also mirrored
/// into Firestore once (see FirebaseBridge.seedAccountsIfNeeded) so
/// credentials are genuinely "kept" in Firebase as requested, without
/// making login itself depend on connectivity.
class DemoAccount {
  final String username;
  final String password;
  final UserRole role;
  const DemoAccount({
    required this.username,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'username': username,
        'password': password,
        'role': role.name,
      };
}

const List<DemoAccount> demoAccounts = [
  DemoAccount(username: 'supervisor', password: 'site123', role: UserRole.supervisor),
  DemoAccount(username: 'engineer', password: 'site123', role: UserRole.siteEngineer),
  DemoAccount(username: 'manager', password: 'site123', role: UserRole.projectManager),
];

enum LoginError { none, emptyFields, userNotFound, wrongPassword, roleMismatch }

class LoginResult {
  final bool success;
  final LoginError error;
  final DemoAccount? account;
  const LoginResult({required this.success, required this.error, this.account});
}

LoginResult validateLogin({
  required String username,
  required String password,
  required UserRole selectedRole,
}) {
  final trimmedUser = username.trim();
  if (trimmedUser.isEmpty || password.isEmpty) {
    return const LoginResult(success: false, error: LoginError.emptyFields);
  }
  final matches = demoAccounts.where(
    (a) => a.username.toLowerCase() == trimmedUser.toLowerCase(),
  );
  if (matches.isEmpty) {
    return const LoginResult(success: false, error: LoginError.userNotFound);
  }
  final account = matches.first;
  if (account.role != selectedRole) {
    return LoginResult(
        success: false, error: LoginError.roleMismatch, account: account);
  }
  if (account.password != password) {
    return LoginResult(
        success: false, error: LoginError.wrongPassword, account: account);
  }
  return LoginResult(success: true, error: LoginError.none, account: account);
}

String loginErrorMessage(LoginError error) {
  switch (error) {
    case LoginError.emptyFields:
      return 'Please enter both username and password.';
    case LoginError.userNotFound:
      return "We couldn't find that username. Check the demo credentials below.";
    case LoginError.wrongPassword:
      return 'Incorrect password. Please try again.';
    case LoginError.roleMismatch:
      return 'These credentials belong to a different role. Select the matching role tile.';
    case LoginError.none:
      return '';
  }
}

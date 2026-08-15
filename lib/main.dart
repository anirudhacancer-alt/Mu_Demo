import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'services/firebase_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Best-effort Firebase init — if firebase_options.dart still has
  // placeholder values, or the device is offline, this fails silently and
  // FirebaseBridge.available stays false. The app runs exactly as before
  // (fully local) in that case; cloud sync is a pure bonus layer.
  await FirebaseBridge.init();
  runApp(const V2EApp());
}

class V2EApp extends StatelessWidget {
  const V2EApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'V2E · SiteVoice.AI',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const RootRouter(),
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.currentRole == null) {
      return const LoginScreen();
    }
    return const HomeShell();
  }
}

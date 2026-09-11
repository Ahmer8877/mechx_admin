import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/supabase_config.dart';
import 'providers/admin_auth_provider.dart';
import 'screens/admin_login_screen.dart';
import 'screens/dashboard_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseConfig.init();
  runApp(const ProviderScope(child: MechXAdminApp()));
}

class MechXAdminApp extends StatelessWidget {
  const MechXAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MechX Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

/// Shows the login screen until an admin session is verified, then
/// switches to the dashboard shell. See AdminAuthNotifier for the
/// role check that guards this.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthProvider);
    return authState.isLoggedIn ? const DashboardShell() : const AdminLoginScreen();
  }
}

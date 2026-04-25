import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/firebase/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'domain/states/auth_state.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/main_layout.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/pages/user_layout.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  // Allow runtime font fetching (Poppins + Inter via google_fonts)
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const ProviderScope(child: ViberantApp()));
}

class ViberantApp extends ConsumerWidget {
  const ViberantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Viberant POS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const _AuthRouter(),
    );
  }
}

/// Watches auth state and routes accordingly.
/// Using a separate widget keeps MyApp lean and avoids unnecessary rebuilds
/// of the entire widget tree on theme changes.
class _AuthRouter extends ConsumerWidget {
  const _AuthRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return _buildHomePage(authState);
  }

  Widget _buildHomePage(AuthState authState) {
    // Initial load or checking stored credentials
    if (authState is AuthInitial || authState is AuthLoading) {
      return const SplashPage();
    }

    // Authenticated — route by role
    if (authState is AuthAuthenticated) {
      return authState.user.isAdmin ? const MainLayout() : const UserLayout();
    }

    // AuthError — go to LoginPage; error message is available on authState
    // for display (LoginPage checks for authProvider error state).
    // AuthUnauthenticated also lands here.
    return const LoginPage();
  }
}

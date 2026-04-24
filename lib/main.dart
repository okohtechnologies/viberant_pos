// lib/main.dart
// CHANGED: AuthError state now passes message to LoginPage
// instead of silently falling through to a blank LoginPage.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viberant_pos/presentation/pages/main_layout.dart';
import 'package:viberant_pos/presentation/pages/user_layout.dart';

import 'core/firebase/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'domain/states/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Viberant POS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: _buildHomePage(authState),
    );
  }

  Widget _buildHomePage(AuthState authState) {
    if (authState is AuthInitial || authState is AuthLoading) {
      return const SplashPage();
    }
    if (authState is AuthAuthenticated) {
      return authState.user.isAdmin ? const MainLayout() : const UserLayout();
    }
    // Pass the error message to LoginPage so it can surface it to the user.
    if (authState is AuthError) {
      return LoginPage(initialError: authState.message);
    }
    return const LoginPage(initialError: '');
  }
}

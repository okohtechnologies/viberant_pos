// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viberant_pos/presentation/pages/main_layout.dart';
import 'package:viberant_pos/presentation/pages/user_layout.dart';

import 'core/firebase/firebase_config.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/pages/auth/login_page.dart';
// Add this import
import 'presentation/providers/auth_provider.dart';
import 'domain/states/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseConfig.initialize();

  // Initialize Google Fonts
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Viberant POS',
      theme: _buildTheme(),
      debugShowCheckedModeBanner: false,
      home: _buildHomePage(authState),
    );
  }

  Widget _buildHomePage(AuthState authState) {
    // Show splash screen while checking auth status
    if (authState is AuthInitial || authState is AuthLoading) {
      return const SplashPage();
    }

    // If authenticated, route based on user role
    if (authState is AuthAuthenticated) {
      return _buildRoleBasedHomePage(authState);
    }

    // If not authenticated or error, go to login page
    return const LoginPage();
  }

  Widget _buildRoleBasedHomePage(AuthAuthenticated authState) {
    final user = authState.user;

    if (user.isAdmin) {
      // Admins get full access to MainLayout with navigation
      return const MainLayout();
    } else {
      // Regular users go directly to POS page with limited navigation
      return const UserLayout(); // Or create a UserLayout if you need limited navigation
    }
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF6C63FF),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF6C63FF),
        secondary: const Color(0xFF4A44B8),
        surface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF2D3748),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }
}

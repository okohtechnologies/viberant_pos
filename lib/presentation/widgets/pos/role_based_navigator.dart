// lib/presentation/widgets/role_based_navigator.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viberant_pos/presentation/pages/auth/login_page.dart';
import 'package:viberant_pos/presentation/pages/main_layout.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart';
import 'package:viberant_pos/presentation/pages/user_layout.dart';

class RoleBasedNavigator extends ConsumerWidget {
  const RoleBasedNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      initial: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      authenticated: (user) {
        // Admin goes to dashboard, User goes directly to POS
        if (user.isAdmin) {
          return const MainLayout(); // Or DashboardPage if different
        } else {
          return const UserLayout(); // POS will be the default for users
        }
      },
      unauthenticated: () => const LoginPage(), // Show login page
      error: (error) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Authentication Error'),
              const SizedBox(height: 8),
              Text(error),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    ref.read(authProvider.notifier).checkAuthStatus(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

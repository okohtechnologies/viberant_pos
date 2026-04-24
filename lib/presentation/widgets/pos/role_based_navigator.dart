// lib/presentation/widgets/pos/role_based_navigator.dart
// Utility widget that shows different content based on
// the current user's role. Use anywhere you need
// admin-only or staff-only UI branches.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';

class RoleGuard extends ConsumerWidget {
  /// Shown when the user is an admin.
  final Widget admin;

  /// Shown when the user is a staff member.
  /// Falls back to [admin] if not provided.
  final Widget? staff;

  /// Shown while auth state is loading or unauthenticated.
  final Widget? fallback;

  const RoleGuard({super.key, required this.admin, this.staff, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth is AuthAuthenticated) {
      if (auth.user.isAdmin) return admin;
      return staff ?? admin;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Convenience widget — only renders [child] for admin users.
/// Renders nothing (or [fallback]) for staff.
class AdminOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnly({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth is AuthAuthenticated && auth.user.isAdmin) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// Convenience widget — only renders [child] for staff users.
/// Renders nothing (or [fallback]) for admins.
class StaffOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const StaffOnly({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth is AuthAuthenticated && !auth.user.isAdmin) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

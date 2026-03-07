// lib/presentation/widgets/role_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import '../providers/auth_provider.dart';

class RoleGuard extends ConsumerWidget {
  final Widget child;
  final bool Function(bool isAdmin) condition;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.child,
    required this.condition,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return fallback ?? const SizedBox.shrink();
    }

    final isAdmin = authState.user.isAdmin;

    if (condition(isAdmin)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

// Pre-built role guard widgets
class AdminOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnly({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      condition: (isAdmin) => isAdmin,
      child: child,
      fallback: fallback,
    );
  }
}

class UserOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const UserOnly({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      condition: (isAdmin) => !isAdmin,
      child: child,
      fallback: fallback,
    );
  }
}

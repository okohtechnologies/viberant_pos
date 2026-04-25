import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/states/auth_state.dart';
import '../providers/auth_provider.dart';

/// Renders [child] only when the authenticated user satisfies [requireAdmin].
/// Falls back to [fallback] (or an empty box) otherwise.
class RoleGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;
  final bool requireAdmin;

  const RoleGuard({
    super.key,
    required this.child,
    this.fallback,
    this.requireAdmin = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth is! AuthAuthenticated) {
      return fallback ?? const SizedBox.shrink();
    }
    if (requireAdmin && !auth.user.isAdmin) {
      return fallback ?? const SizedBox.shrink();
    }
    return child;
  }
}

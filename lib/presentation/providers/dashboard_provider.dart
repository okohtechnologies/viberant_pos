import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/states/auth_state.dart';
import 'auth_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

/// Fixed: uses today-scoped listener (not full collection).
/// autoDispose: stream is released when Dashboard tab is inactive.
final dashboardStatsProvider = StreamProvider.autoDispose<DashboardStats>((
  ref,
) {
  final repo = ref.read(dashboardRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState is! AuthAuthenticated) {
    return Stream.value(DashboardStats.empty());
  }

  final businessId = authState.user.businessId;
  if (businessId.isEmpty) {
    debugPrint('❌ Dashboard: empty businessId');
    return Stream.value(DashboardStats.empty());
  }

  debugPrint('📊 Dashboard streaming for: $businessId');
  return repo.getDashboardStats(businessId);
});

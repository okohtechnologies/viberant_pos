// lib/presentation/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/entities/dashboard_entity.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardStatsProvider = StreamProvider.autoDispose<DashboardStats>((
  ref,
) {
  final dashboardRepository = ref.read(dashboardRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState is! AuthAuthenticated) {
    return Stream.value(DashboardStats.empty());
  }

  // FIX: Pass businessId instead of user.id
  final businessId = authState.user.businessId;
  if (businessId.isEmpty) {
    print('❌ Dashboard: No businessId found for user');
    return Stream.value(DashboardStats.empty());
  }

  print('📊 Dashboard: Loading stats for business: $businessId');
  return dashboardRepository.getDashboardStats(businessId);
});

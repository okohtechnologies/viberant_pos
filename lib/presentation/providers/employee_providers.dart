// lib/presentation/providers/employee_providers.dart
// NEW: Provides Riverpod-native streams for employee screens.
// Replaces the raw FirebaseFirestore.instance StreamBuilders in:
//   - OrderHistoryPage
//   - TodaySalesPage
// Both screens should be converted to ConsumerWidget and ref.watch() these.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/sale_repository_provider.dart';
import '../../domain/entities/sale_entity.dart';
import 'auth_provider.dart';

/// Today's completed sales for the current user's business.
/// Used by TodaySalesPage.
final todaySalesProvider = StreamProvider.autoDispose<List<SaleEntity>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return const Stream.empty();

  final repo = ref.read(saleRepositoryProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  return repo.getSalesWithFilters(
    businessId: auth.user.businessId,
    startDate: startOfDay,
    endDate: today,
  );
});

/// Full order history for the currently logged-in cashier only.
/// Used by OrderHistoryPage.
final myOrderHistoryProvider = StreamProvider.autoDispose<List<SaleEntity>>((
  ref,
) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return const Stream.empty();

  final repo = ref.read(saleRepositoryProvider);

  return repo.getSalesWithFilters(
    businessId: auth.user.businessId,
    cashierId: auth.user.id,
  );
});

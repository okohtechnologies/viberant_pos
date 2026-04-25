import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../../domain/states/auth_state.dart';

// Single source of truth for SaleRepository — removes duplicate declaration
// that was inside cart_provider.dart
final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository();
});

// ── Employee-specific providers ───────────────────────────────────────────────
// Replaces raw FirebaseFirestore.instance calls in OrderHistoryPage,
// TodaySalesPage, and UserHomePage._buildTodaysSummary()

/// Today's sales for the authenticated user's business
final todaySalesProvider = StreamProvider.autoDispose<List<SaleEntity>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return const Stream.empty();

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  return ref
      .read(saleRepositoryProvider)
      .getSalesWithFilters(
        businessId: auth.user.businessId,
        startDate: startOfDay,
        endDate: today,
      );
});

/// This cashier's own order history (filtered by cashierId)
final myOrderHistoryProvider = StreamProvider.autoDispose<List<SaleEntity>>((
  ref,
) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return const Stream.empty();

  return ref
      .read(saleRepositoryProvider)
      .getSalesWithFilters(
        businessId: auth.user.businessId,
        cashierId: auth.user.id,
      );
});

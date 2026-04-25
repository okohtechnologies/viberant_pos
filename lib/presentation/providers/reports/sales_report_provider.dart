// lib/presentation/providers/reports/sales_report_provider.dart
//
// KEY FIX: salesReportDataProvider is now .autoDispose so the Firestore
// stream is released when the Reports screen is popped.
// Previously it was a permanent StreamProvider leaking a listener for life.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../auth_provider.dart';
import '../cart_provider.dart'; // re-exports saleRepositoryProvider

// ── Filters state ─────────────────────────────────────────────────────────────
class SalesReportFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final PaymentMethod? paymentMethod;
  final String? cashierId;
  final SaleStatus? status;
  final int limit;

  const SalesReportFilters({
    this.startDate,
    this.endDate,
    this.paymentMethod,
    this.cashierId,
    this.status,
    this.limit = 200,
  });

  SalesReportFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    String? cashierId,
    SaleStatus? status,
    int? limit,
    bool clearPayment = false,
    bool clearCashier = false,
    bool clearStatus = false,
  }) => SalesReportFilters(
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    paymentMethod: clearPayment ? null : (paymentMethod ?? this.paymentMethod),
    cashierId: clearCashier ? null : (cashierId ?? this.cashierId),
    status: clearStatus ? null : (status ?? this.status),
    limit: limit ?? this.limit,
  );
}

final salesReportFiltersProvider = StateProvider<SalesReportFilters>((ref) {
  final now = DateTime.now();
  return SalesReportFilters(
    startDate: DateTime(now.year, now.month, 1),
    endDate: now,
  );
});

// ── Derived: current business ID ──────────────────────────────────────────────
final currentBusinessIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is AuthAuthenticated ? auth.user.businessId : null;
});

// ── FIXED: autoDispose so stream is released when screen is popped ────────────
final salesReportDataProvider = StreamProvider.autoDispose<List<SaleEntity>>((
  ref,
) {
  final filters = ref.watch(salesReportFiltersProvider);
  final repo = ref.watch(saleRepositoryProvider);
  final businessId = ref.watch(currentBusinessIdProvider);

  if (businessId == null) return const Stream.empty();

  return repo.getSalesWithFilters(
    businessId: businessId,
    startDate: filters.startDate,
    endDate: filters.endDate,
    paymentMethod: filters.paymentMethod,
    cashierId: filters.cashierId,
    status: filters.status,
    limit: filters.limit,
  );
});

// ── Summary (derived, no extra Firestore read) ────────────────────────────────
final salesSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.watch(saleRepositoryProvider);
  final filters = ref.watch(salesReportFiltersProvider);
  final businessId = ref.watch(currentBusinessIdProvider);

  if (businessId == null) {
    return {
      'totalRevenue': 0.0,
      'totalTransactions': 0,
      'averageSale': 0.0,
      'paymentMethodCounts': <String, int>{},
    };
  }

  return repo.getSalesSummary(
    businessId: businessId,
    startDate:
        filters.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
    endDate: filters.endDate ?? DateTime.now(),
  );
});

// ── Access control ────────────────────────────────────────────────────────────
final canViewReportsProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth is AuthAuthenticated && auth.user.isAdmin;
});

// ── Formatting helpers ────────────────────────────────────────────────────────
final dateFormatProvider = Provider<DateFormat>(
  (ref) => DateFormat('dd/MM/yyyy'),
);
final currencyFormatProvider = Provider<NumberFormat>(
  (ref) => NumberFormat.currency(symbol: '₵ ', decimalDigits: 2),
);

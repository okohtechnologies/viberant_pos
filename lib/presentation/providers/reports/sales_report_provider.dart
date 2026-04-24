// lib/presentation/providers/reports/sales_report_provider.dart
// FIX: salesReportDataProvider changed to StreamProvider.autoDispose so the
// sales stream is released when the Reports screen is not in view.
// FIX: saleRepositoryProvider import moved to its own file — import from there.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/sale_repository_provider.dart';
import '../../../domain/entities/sale_entity.dart';
import '../auth_provider.dart';

class SalesReportFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final PaymentMethod? paymentMethod;
  final String? cashierId;
  final SaleStatus? status;
  final int limit;

  SalesReportFilters({
    this.startDate,
    this.endDate,
    this.paymentMethod,
    this.cashierId,
    this.status,
    this.limit = 100,
  });

  SalesReportFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    String? cashierId,
    SaleStatus? status,
    int? limit,
  }) => SalesReportFilters(
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    cashierId: cashierId ?? this.cashierId,
    status: status ?? this.status,
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

final currentBusinessIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is AuthAuthenticated ? auth.user.businessId : null;
});

// FIXED: was StreamProvider (never disposed) → now autoDispose
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

final salesSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.watch(saleRepositoryProvider);
  final filters = ref.watch(salesReportFiltersProvider);
  final businessId = ref.watch(currentBusinessIdProvider);

  if (businessId == null) {
    return {'success': false, 'error': 'Not authenticated'};
  }

  return repo.getSalesSummary(
    businessId: businessId,
    startDate:
        filters.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
    endDate: filters.endDate ?? DateTime.now(),
  );
});

final topProductsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repo = ref.watch(saleRepositoryProvider);
      final filters = ref.watch(salesReportFiltersProvider);
      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId == null) return [];
      return repo.getTopSellingProducts(
        businessId: businessId,
        startDate:
            filters.startDate ??
            DateTime.now().subtract(const Duration(days: 30)),
        endDate: filters.endDate ?? DateTime.now(),
        limit: 5,
      );
    });

final cashierPerformanceProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repo = ref.watch(saleRepositoryProvider);
      final filters = ref.watch(salesReportFiltersProvider);
      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId == null) return [];
      return repo.getCashierPerformance(
        businessId: businessId,
        startDate:
            filters.startDate ??
            DateTime.now().subtract(const Duration(days: 30)),
        endDate: filters.endDate ?? DateTime.now(),
      );
    });

final todaySalesByHourProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
      final repo = ref.watch(saleRepositoryProvider);
      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId == null) return {};
      return repo.getTodaySalesByHour(businessId);
    });

final exportSalesDataProvider = FutureProvider.autoDispose
    .family<
      List<Map<String, dynamic>>,
      ({DateTime? startDate, DateTime? endDate})
    >((ref, params) async {
      final repo = ref.watch(saleRepositoryProvider);
      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId == null) return [];
      return repo.exportSalesData(
        businessId: businessId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

final canViewReportsProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth is AuthAuthenticated && (auth.user.isAdmin || auth.user.isUser);
});

final dateFormatProvider = Provider<DateFormat>(
  (ref) => DateFormat('dd/MM/yyyy'),
);

final currencyFormatProvider = Provider<NumberFormat>(
  (ref) => NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2),
);

final availableCashiersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repo = ref.watch(saleRepositoryProvider);
      final businessId = ref.watch(currentBusinessIdProvider);
      final filters = ref.watch(salesReportFiltersProvider);
      if (businessId == null) return [];

      try {
        final sales = await repo
            .getSalesWithFilters(
              businessId: businessId,
              startDate: filters.startDate,
              endDate: filters.endDate,
              limit: 1000,
            )
            .first;

        final cashiersMap = <String, Map<String, dynamic>>{};
        for (final sale in sales) {
          cashiersMap.putIfAbsent(
            sale.cashierId,
            () => {
              'id': sale.cashierId,
              'name': sale.cashierName,
              'salesCount': 0,
            },
          );
          cashiersMap[sale.cashierId]!['salesCount'] =
              (cashiersMap[sale.cashierId]!['salesCount'] as int) + 1;
        }

        return cashiersMap.values.toList()..sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        );
      } catch (e) {
        debugPrint('Error getting cashiers: $e');
        return [];
      }
    });

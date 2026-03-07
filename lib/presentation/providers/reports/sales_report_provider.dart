// lib/presentation/providers/reports/sales_report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/cart_provider.dart';
// ignore: unused_import
import '../../../data/repositories/sale_repository.dart';
import '../../../domain/entities/sale_entity.dart';
import '../auth_provider.dart';

// State for sales report filters
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
  }) {
    return SalesReportFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashierId: cashierId ?? this.cashierId,
      status: status ?? this.status,
      limit: limit ?? this.limit,
    );
  }
}

// Provider for sales report filters
final salesReportFiltersProvider = StateProvider<SalesReportFilters>((ref) {
  final now = DateTime.now();
  return SalesReportFilters(
    startDate: DateTime(now.year, now.month, 1), // Start of month
    endDate: now,
  );
});

// Provider to get current business ID
final currentBusinessIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);

  if (authState is AuthAuthenticated) {
    return authState.user.businessId;
  }
  return null;
});

// Provider for filtered sales data
final salesReportDataProvider = StreamProvider<List<SaleEntity>>((ref) {
  final filters = ref.watch(salesReportFiltersProvider);
  final repository = ref.watch(saleRepositoryProvider);
  final businessId = ref.watch(currentBusinessIdProvider);

  // Check if user is authenticated
  if (businessId == null) {
    return const Stream.empty(); // No data if not authenticated
  }

  return repository.getSalesWithFilters(
    businessId: businessId,
    startDate: filters.startDate,
    endDate: filters.endDate,
    paymentMethod: filters.paymentMethod,
    cashierId: filters.cashierId,
    status: filters.status,
    limit: filters.limit,
  );
});

// Provider for sales summary
final salesSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(saleRepositoryProvider);
  final filters = ref.watch(salesReportFiltersProvider);
  final businessId = ref.watch(currentBusinessIdProvider);

  // Check if user is authenticated
  if (businessId == null) {
    return {
      'totalRevenue': 0.0,
      'totalTransactions': 0,
      'totalItemsSold': 0,
      'averageSale': 0.0,
      'paymentMethodCounts': {},
      'dailySales': {},
      'success': false,
      'error': 'User not authenticated',
    };
  }

  return repository.getSalesSummary(
    businessId: businessId,
    startDate:
        filters.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
    endDate: filters.endDate ?? DateTime.now(),
  );
});

// Provider for top selling products
final topProductsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(saleRepositoryProvider);
  final filters = ref.watch(salesReportFiltersProvider);
  final businessId = ref.watch(currentBusinessIdProvider);

  // Check if user is authenticated
  if (businessId == null) {
    return [];
  }

  return repository.getTopSellingProducts(
    businessId: businessId,
    startDate:
        filters.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
    endDate: filters.endDate ?? DateTime.now(),
    limit: 5,
  );
});

// Provider for cashier performance
final cashierPerformanceProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(saleRepositoryProvider);
  final filters = ref.watch(salesReportFiltersProvider);
  final businessId = ref.watch(currentBusinessIdProvider);

  // Check if user is authenticated
  if (businessId == null) {
    return [];
  }

  return repository.getCashierPerformance(
    businessId: businessId,
    startDate:
        filters.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
    endDate: filters.endDate ?? DateTime.now(),
  );
});

// Provider for today's sales by hour
final todaySalesByHourProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final repository = ref.watch(saleRepositoryProvider);
  final businessId = ref.watch(currentBusinessIdProvider);

  // Check if user is authenticated
  if (businessId == null) {
    return {};
  }

  return repository.getTodaySalesByHour(businessId);
});

// Provider for export sales data
final exportSalesDataProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({DateTime? startDate, DateTime? endDate})
    >((ref, params) async {
      final repository = ref.watch(saleRepositoryProvider);
      final businessId = ref.watch(currentBusinessIdProvider);

      // Check if user is authenticated
      if (businessId == null) {
        return [];
      }

      return repository.exportSalesData(
        businessId: businessId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

// Provider to check if user can view reports
final canViewReportsProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);

  if (authState is AuthAuthenticated) {
    return authState.user.isAdmin || authState.user.isUser;
  }
  return false;
});

// Helper provider for date formatting
final dateFormatProvider = Provider<DateFormat>((ref) {
  return DateFormat('dd/MM/yyyy');
});

// Helper provider for currency formatting
final currencyFormatProvider = Provider<NumberFormat>((ref) {
  return NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
});

// Additional: Get all cashiers for filter dropdown
final availableCashiersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(saleRepositoryProvider);
  final businessId = ref.watch(currentBusinessIdProvider);
  final filters = ref.watch(salesReportFiltersProvider);

  if (businessId == null) {
    return [];
  }

  try {
    // First get all sales to extract cashiers
    final sales = await repository
        .getSalesWithFilters(
          businessId: businessId,
          startDate: filters.startDate,
          endDate: filters.endDate,
          limit: 1000,
        )
        .first;

    // Extract unique cashiers
    final cashiersMap = <String, Map<String, dynamic>>{};

    for (final sale in sales) {
      if (!cashiersMap.containsKey(sale.cashierId)) {
        cashiersMap[sale.cashierId] = {
          'id': sale.cashierId,
          'name': sale.cashierName,
          'salesCount': 0,
        };
      }
      cashiersMap[sale.cashierId]!['salesCount']++;
    }

    // Convert to list and sort by name
    return cashiersMap.values.toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  } catch (e) {
    print('Error getting cashiers: $e');
    return [];
  }
});

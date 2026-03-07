// lib/data/repositories/sale_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sale_entity.dart';

class SaleRepository {
  final FirebaseFirestore _firestore;

  SaleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Record a new sale and update product stocks atomically
  Future<void> processSale(SaleEntity sale) async {
    try {
      final batch = _firestore.batch();

      // Reference for the sale document
      final saleRef = _firestore
          .collection('businesses')
          .doc(sale.businessId)
          .collection('sales')
          .doc(sale.id);

      batch.set(saleRef, sale.toMap());

      // Update product stocks
      for (final cartItem in sale.items) {
        final productRef = _firestore
            .collection('businesses')
            .doc(sale.businessId)
            .collection('products')
            .doc(cartItem.product.id);

        // Fetch product from Firestore to verify it exists
        final productSnap = await productRef.get();
        if (!productSnap.exists) {
          throw Exception(
            'Product not found in database: ${cartItem.product.name}',
          );
        }

        final currentStock = (productSnap.data()?['stock'] ?? 0).toInt();
        final newStock = currentStock - cartItem.quantity;

        if (newStock < 0) {
          throw Exception(
            'Insufficient stock for ${cartItem.product.name}. Available: $currentStock, Requested: ${cartItem.quantity}',
          );
        }

        batch.update(productRef, {
          'stock': newStock,
          'updatedAt': Timestamp.now(),
        });
      }

      // Commit batch
      await batch.commit();
      print('✅ Sale processed and stock updated successfully');
    } catch (e) {
      print('❌ Failed to process sale: $e');
      throw Exception('Failed to process sale: $e');
    }
  }

  /// Stream sales for dashboard
  Stream<List<SaleEntity>> getSalesStream(String businessId, {int? limit}) {
    var query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('sales')
        .orderBy('saleDate', descending: true);

    if (limit != null) query = query.limit(limit);

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => SaleEntity.fromFirestore(doc)).toList(),
    );
  }

  /// 🔥 NEW: Fetch sales with filters for reports
  Stream<List<SaleEntity>> getSalesWithFilters({
    required String businessId,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    String? cashierId,
    SaleStatus? status,
    int? limit,
  }) {
    var query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('sales')
        .orderBy('saleDate', descending: true);

    // Apply date filters
    if (startDate != null) {
      query = query.where('saleDate', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('saleDate', isLessThanOrEqualTo: endDate);
    }

    // Apply payment method filter
    if (paymentMethod != null) {
      query = query.where(
        'paymentMethod',
        isEqualTo: _paymentMethodToString(paymentMethod),
      );
    }

    // Apply cashier filter
    if (cashierId != null && cashierId.isNotEmpty) {
      query = query.where('cashierId', isEqualTo: cashierId);
    }

    // Apply status filter
    if (status != null) {
      query = query.where('status', isEqualTo: _saleStatusToString(status));
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => SaleEntity.fromFirestore(doc)).toList(),
    );
  }

  /// 🔥 NEW: Get sales summary for dashboard
  Future<Map<String, dynamic>> getSalesSummary({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final salesQuery = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where('saleDate', isGreaterThanOrEqualTo: startDate)
          .where('saleDate', isLessThanOrEqualTo: endDate)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRevenue = 0;
      int totalTransactions = salesQuery.docs.length;
      int totalItemsSold = 0;
      final paymentMethodCounts = <String, int>{};
      final dailySales = <String, double>{};

      for (final doc in salesQuery.docs) {
        try {
          final sale = SaleEntity.fromFirestore(doc);
          totalRevenue += sale.finalAmount;
          totalItemsSold += sale.totalItems;

          // Count payment methods
          final method = sale.paymentMethodString;
          paymentMethodCounts[method] = (paymentMethodCounts[method] ?? 0) + 1;

          // Group by day (YYYY-MM-DD format)
          final dayKey =
              '${sale.saleDate.year}-${sale.saleDate.month.toString().padLeft(2, '0')}-${sale.saleDate.day.toString().padLeft(2, '0')}';
          dailySales[dayKey] = (dailySales[dayKey] ?? 0) + sale.finalAmount;
        } catch (e) {
          print('Error parsing sale document: $e');
          continue;
        }
      }

      final averageSale = totalTransactions > 0
          ? totalRevenue / totalTransactions
          : 0;

      return {
        'totalRevenue': totalRevenue,
        'totalTransactions': totalTransactions,
        'totalItemsSold': totalItemsSold,
        'averageSale': averageSale,
        'paymentMethodCounts': paymentMethodCounts,
        'dailySales': dailySales,
        'success': true,
      };
    } catch (e) {
      print('Error getting sales summary: $e');
      return {
        'totalRevenue': 0.0,
        'totalTransactions': 0,
        'totalItemsSold': 0,
        'averageSale': 0.0,
        'paymentMethodCounts': {},
        'dailySales': {},
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔥 NEW: Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final salesQuery = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where('saleDate', isGreaterThanOrEqualTo: startDate)
          .where('saleDate', isLessThanOrEqualTo: endDate)
          .where('status', isEqualTo: 'completed')
          .get();

      final productSales = <String, Map<String, dynamic>>{};

      for (final doc in salesQuery.docs) {
        try {
          final sale = SaleEntity.fromFirestore(doc);
          for (final item in sale.items) {
            final productId = item.product.id;
            final productName = item.product.name;
            final quantity = item.quantity;
            final revenue = item.subtotal;

            if (!productSales.containsKey(productId)) {
              productSales[productId] = {
                'id': productId,
                'name': productName,
                'quantity': 0,
                'revenue': 0.0,
                'unitPrice': item.product.price,
              };
            }

            productSales[productId]!['quantity'] += quantity;
            productSales[productId]!['revenue'] += revenue;
          }
        } catch (e) {
          print('Error parsing sale for top products: $e');
          continue;
        }
      }

      // Convert to list and sort by revenue (descending)
      final productList = productSales.values.toList();
      productList.sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
      );

      // Return limited results
      return productList.take(limit).toList();
    } catch (e) {
      print('Error getting top products: $e');
      return [];
    }
  }

  /// 🔥 NEW: Get sales by hour for today
  Future<Map<String, double>> getTodaySalesByHour(String businessId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final salesQuery = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where('saleDate', isGreaterThanOrEqualTo: startOfDay)
          .where('saleDate', isLessThanOrEqualTo: endOfDay)
          .where('status', isEqualTo: 'completed')
          .get();

      final hourlySales = <String, double>{};

      // Initialize all hours with 0
      for (int hour = 0; hour < 24; hour++) {
        hourlySales[hour.toString().padLeft(2, '0')] = 0.0;
      }

      for (final doc in salesQuery.docs) {
        try {
          final sale = SaleEntity.fromFirestore(doc);
          final hour = sale.saleDate.hour.toString().padLeft(2, '0');
          hourlySales[hour] = (hourlySales[hour] ?? 0) + sale.finalAmount;
        } catch (e) {
          continue;
        }
      }

      return hourlySales;
    } catch (e) {
      print('Error getting hourly sales: $e');
      return {};
    }
  }

  /// 🔥 NEW: Get cashier performance
  Future<List<Map<String, dynamic>>> getCashierPerformance({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final salesQuery = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where('saleDate', isGreaterThanOrEqualTo: startDate)
          .where('saleDate', isLessThanOrEqualTo: endDate)
          .where('status', isEqualTo: 'completed')
          .get();

      final cashierStats = <String, Map<String, dynamic>>{};

      for (final doc in salesQuery.docs) {
        try {
          final sale = SaleEntity.fromFirestore(doc);
          final cashierId = sale.cashierId;
          final cashierName = sale.cashierName;

          if (!cashierStats.containsKey(cashierId)) {
            cashierStats[cashierId] = {
              'cashierId': cashierId,
              'cashierName': cashierName,
              'salesCount': 0,
              'totalRevenue': 0.0,
              'totalItems': 0,
            };
          }

          cashierStats[cashierId]!['salesCount'] += 1;
          cashierStats[cashierId]!['totalRevenue'] += sale.finalAmount;
          cashierStats[cashierId]!['totalItems'] += sale.totalItems;
        } catch (e) {
          continue;
        }
      }

      // Convert to list and sort by revenue
      final cashierList = cashierStats.values.toList();
      cashierList.sort(
        (a, b) => (b['totalRevenue'] as double).compareTo(
          a['totalRevenue'] as double,
        ),
      );

      return cashierList;
    } catch (e) {
      print('Error getting cashier performance: $e');
      return [];
    }
  }

  /// 🔥 NEW: Export sales data
  Future<List<Map<String, dynamic>>> exportSalesData({
    required String businessId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .orderBy('saleDate', descending: true);

      if (startDate != null) {
        query = query.where('saleDate', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('saleDate', isLessThanOrEqualTo: endDate);
      }

      final salesQuery = await query.get();

      final exportData = <Map<String, dynamic>>[];

      for (final doc in salesQuery.docs) {
        try {
          final sale = SaleEntity.fromFirestore(doc);
          exportData.add({
            'Transaction ID': sale.transactionId,
            'Date': sale.saleDate.toIso8601String(),
            'Cashier': sale.cashierName,
            'Customer': sale.customerName ?? 'Walk-in',
            'Payment Method': _formatPaymentMethodForExport(sale.paymentMethod),
            'Items Count': sale.totalItems,
            'Subtotal': sale.totalAmount,
            'Tax': sale.taxAmount,
            'Discount': sale.discountAmount,
            'Total': sale.finalAmount,
            'Status': _saleStatusToString(sale.status),
          });
        } catch (e) {
          continue;
        }
      }

      return exportData;
    } catch (e) {
      print('Error exporting sales data: $e');
      return [];
    }
  }

  // Helper methods for enum conversion
  String _paymentMethodToString(PaymentMethod method) {
    return method.toString().split('.').last;
  }

  String _saleStatusToString(SaleStatus status) {
    return status.toString().split('.').last;
  }

  String _formatPaymentMethodForExport(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.momo:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }
}

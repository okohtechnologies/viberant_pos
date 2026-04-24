// lib/data/repositories/sale_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/sale_entity.dart';

class SaleRepository {
  final FirebaseFirestore _firestore;

  SaleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  //  WRITE — process a sale atomically
  //  FIX: replaced batch() with runTransaction() to eliminate the
  //  read-then-write race condition that could cause stock to go negative
  //  when two cashiers sell the last unit simultaneously.
  // ─────────────────────────────────────────────
  Future<void> processSale(SaleEntity sale) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Build all product refs up front
        final productRefs = sale.items
            .map(
              (item) => _firestore
                  .collection('businesses')
                  .doc(sale.businessId)
                  .collection('products')
                  .doc(item.product.id),
            )
            .toList();

        // 2. Read all product docs inside the transaction (ensures isolation)
        final productSnaps = await Future.wait(
          productRefs.map((ref) => transaction.get(ref)),
        );

        // 3. Validate all stocks BEFORE any writes
        for (int i = 0; i < sale.items.length; i++) {
          final item = sale.items[i];
          final snap = productSnaps[i];
          if (!snap.exists) {
            throw Exception('Product not found: ${item.product.name}');
          }
          final stock =
              ((snap.data() as Map<String, dynamic>)['stock'] ?? 0) as num;
          if (stock.toInt() < item.quantity) {
            throw Exception(
              'Insufficient stock for ${item.product.name}. '
              'Have: ${stock.toInt()}, Need: ${item.quantity}',
            );
          }
        }

        // 4. Write the sale document
        final saleRef = _firestore
            .collection('businesses')
            .doc(sale.businessId)
            .collection('sales')
            .doc(sale.id);
        transaction.set(saleRef, sale.toMap());

        // 5. Write customer upsert if customerName provided
        if (sale.customerName != null && sale.customerName!.isNotEmpty) {
          final customerKey = sale.customerName!.toLowerCase().replaceAll(
            ' ',
            '_',
          );
          final customerRef = _firestore
              .collection('businesses')
              .doc(sale.businessId)
              .collection('customers')
              .doc(customerKey);
          transaction.set(customerRef, {
            'name': sale.customerName,
            'totalSpent': FieldValue.increment(sale.finalAmount),
            'visits': FieldValue.increment(1),
            'lastVisit': Timestamp.fromDate(sale.saleDate),
          }, SetOptions(merge: true));
        }

        // 6. Decrement stocks (atomic increment — no computed newStock value)
        for (int i = 0; i < sale.items.length; i++) {
          transaction.update(productRefs[i], {
            'stock': FieldValue.increment(-sale.items[i].quantity),
            'updatedAt': Timestamp.now(),
          });
        }
      });

      debugPrint('✅ Sale processed atomically');
    } catch (e) {
      debugPrint('❌ Failed to process sale: $e');
      throw Exception('Failed to process sale: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  READ — streams
  // ─────────────────────────────────────────────

  Stream<List<SaleEntity>> getSalesStream(String businessId, {int? limit}) {
    var query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('sales')
        .orderBy('saleDate', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
      (s) => s.docs.map((d) => SaleEntity.fromFirestore(d)).toList(),
    );
  }

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

    if (startDate != null) {
      query = query.where(
        'saleDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'saleDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }
    if (paymentMethod != null) {
      query = query.where(
        'paymentMethod',
        isEqualTo: paymentMethod.toString().split('.').last,
      );
    }
    if (cashierId != null && cashierId.isNotEmpty) {
      query = query.where('cashierId', isEqualTo: cashierId);
    }
    if (status != null) {
      query = query.where(
        'status',
        isEqualTo: status.toString().split('.').last,
      );
    }
    if (limit != null) query = query.limit(limit);

    return query.snapshots().map(
      (s) => s.docs.map((d) => SaleEntity.fromFirestore(d)).toList(),
    );
  }

  // ─────────────────────────────────────────────
  //  READ — futures (for report aggregations)
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getSalesSummary({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where(
            'saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRevenue = 0;
      int totalItemsSold = 0;
      final paymentMethodCounts = <String, int>{};
      final dailySales = <String, double>{};

      for (final doc in snap.docs) {
        try {
          final sale = SaleEntity.fromFirestore(doc);
          totalRevenue += sale.finalAmount;
          totalItemsSold += sale.totalItems;
          final method = sale.paymentMethodString;
          paymentMethodCounts[method] = (paymentMethodCounts[method] ?? 0) + 1;
          final dayKey =
              '${sale.saleDate.year}-${sale.saleDate.month.toString().padLeft(2, '0')}-${sale.saleDate.day.toString().padLeft(2, '0')}';
          dailySales[dayKey] = (dailySales[dayKey] ?? 0) + sale.finalAmount;
        } catch (e) {
          continue;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalTransactions': snap.docs.length,
        'totalItemsSold': totalItemsSold,
        'averageSale': snap.docs.isNotEmpty
            ? totalRevenue / snap.docs.length
            : 0.0,
        'paymentMethodCounts': paymentMethodCounts,
        'dailySales': dailySales,
        'success': true,
      };
    } catch (e) {
      debugPrint('Error getting sales summary: $e');
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

  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final snap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where(
            'saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'completed')
          .get();

      final productSales = <String, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        try {
          final sale = SaleEntity.fromFirestore(doc);
          for (final item in sale.items) {
            final id = item.product.id;
            productSales.putIfAbsent(
              id,
              () => {
                'id': id,
                'name': item.product.name,
                'quantity': 0,
                'revenue': 0.0,
                'unitPrice': item.product.price,
              },
            );
            productSales[id]!['quantity'] =
                (productSales[id]!['quantity'] as int) + item.quantity;
            productSales[id]!['revenue'] =
                (productSales[id]!['revenue'] as double) + item.subtotal;
          }
        } catch (_) {}
      }

      final list = productSales.values.toList()
        ..sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
        );
      return list.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting top products: $e');
      return [];
    }
  }

  Future<Map<String, double>> getTodaySalesByHour(String businessId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final snap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where(
            'saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('status', isEqualTo: 'completed')
          .get();

      final hourly = <String, double>{
        for (int h = 0; h < 24; h++) h.toString().padLeft(2, '0'): 0.0,
      };
      for (final doc in snap.docs) {
        try {
          final sale = SaleEntity.fromFirestore(doc);
          final h = sale.saleDate.hour.toString().padLeft(2, '0');
          hourly[h] = (hourly[h] ?? 0) + sale.finalAmount;
        } catch (_) {}
      }
      return hourly;
    } catch (e) {
      debugPrint('Error getting hourly sales: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getCashierPerformance({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where(
            'saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'completed')
          .get();

      final stats = <String, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        try {
          final sale = SaleEntity.fromFirestore(doc);
          stats.putIfAbsent(
            sale.cashierId,
            () => {
              'cashierId': sale.cashierId,
              'cashierName': sale.cashierName,
              'salesCount': 0,
              'totalRevenue': 0.0,
              'totalItems': 0,
            },
          );
          stats[sale.cashierId]!['salesCount'] =
              (stats[sale.cashierId]!['salesCount'] as int) + 1;
          stats[sale.cashierId]!['totalRevenue'] =
              (stats[sale.cashierId]!['totalRevenue'] as double) +
              sale.finalAmount;
          stats[sale.cashierId]!['totalItems'] =
              (stats[sale.cashierId]!['totalItems'] as int) + sale.totalItems;
        } catch (_) {}
      }

      return stats.values.toList()..sort(
        (a, b) => (b['totalRevenue'] as double).compareTo(
          a['totalRevenue'] as double,
        ),
      );
    } catch (e) {
      debugPrint('Error getting cashier performance: $e');
      return [];
    }
  }

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
        query = query.where(
          'saleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'saleDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snap = await query.get();
      return snap.docs.map((doc) {
        final sale = SaleEntity.fromFirestore(doc);
        return {
          'Transaction ID': sale.transactionId,
          'Date': sale.saleDate.toIso8601String(),
          'Cashier': sale.cashierName,
          'Customer': sale.customerName ?? 'Walk-in',
          'Payment Method': sale.paymentMethodString,
          'Items Count': sale.totalItems,
          'Subtotal': sale.totalAmount,
          'Tax': sale.taxAmount,
          'Discount': sale.discountAmount,
          'Total': sale.finalAmount,
          'Status': sale.status.toString().split('.').last,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error exporting sales data: $e');
      return [];
    }
  }
}

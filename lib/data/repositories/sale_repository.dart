import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/sale_entity.dart';

class SaleRepository {
  final FirebaseFirestore _firestore;

  SaleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Process a sale atomically using Firestore Transaction.
  /// Fixes race condition: uses transaction reads before any writes,
  /// ensuring concurrent sales don't silently oversell stock.
  Future<void> processSale(SaleEntity sale) async {
    return _firestore
        .runTransaction((transaction) async {
          // 1. Build all product refs
          final productRefs = sale.items
              .map(
                (item) => _firestore
                    .collection('businesses')
                    .doc(sale.businessId)
                    .collection('products')
                    .doc(item.product.id),
              )
              .toList();

          // 2. Read all product docs inside the transaction
          final productSnaps = await Future.wait(
            productRefs.map((ref) => transaction.get(ref)),
          );

          // 3. Validate ALL stocks before any writes
          for (int i = 0; i < sale.items.length; i++) {
            final item = sale.items[i];
            final snap = productSnaps[i];
            if (!snap.exists) {
              throw Exception('Product not found: ${item.product.name}');
            }
            final stock = (snap.data()?['stock'] ?? 0) as int;
            if (stock < item.quantity) {
              throw Exception(
                'Insufficient stock for ${item.product.name}. '
                'Available: $stock, Requested: ${item.quantity}',
              );
            }
          }

          // 4. Write sale document
          final saleRef = _firestore
              .collection('businesses')
              .doc(sale.businessId)
              .collection('sales')
              .doc(sale.id);
          transaction.set(saleRef, sale.toMap());

          // 5. Decrement stock atomically using FieldValue.increment
          for (int i = 0; i < sale.items.length; i++) {
            transaction.update(productRefs[i], {
              'stock': FieldValue.increment(-sale.items[i].quantity),
              'updatedAt': Timestamp.now(),
            });
          }

          // 6. Upsert customer record if named customer (fixes aggregation scaling)
          final name = sale.customerName?.trim() ?? '';
          if (name.isNotEmpty) {
            final customerRef = _firestore
                .collection('businesses')
                .doc(sale.businessId)
                .collection('customers')
                .doc(name.toLowerCase().replaceAll(RegExp(r'\s+'), '_'));
            transaction.set(customerRef, {
              'name': name,
              'totalSpent': FieldValue.increment(sale.finalAmount),
              'visits': FieldValue.increment(1),
              'lastVisit': Timestamp.fromDate(sale.saleDate),
            }, SetOptions(merge: true));
          }
        })
        .then((_) {
          debugPrint('✅ Sale processed atomically: ${sale.transactionId}');
        })
        .catchError((e) {
          debugPrint('❌ Sale transaction failed: $e');
          throw Exception('Failed to process sale: $e');
        });
  }

  /// Stream all sales for a business (reports / admin).
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

  /// Filtered sales stream — used by reports screen.
  Stream<List<SaleEntity>> getSalesWithFilters({
    required String businessId,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    String? cashierId,
    SaleStatus? status,
    int limit = 200,
  }) {
    var query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('sales')
        .orderBy('saleDate', descending: true)
        .limit(limit);

    if (startDate != null) {
      query = query.where(
        'saleDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      query = query.where(
        'saleDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
      );
    }
    if (paymentMethod != null) {
      query = query.where(
        'paymentMethod',
        isEqualTo: _paymentMethodToString(paymentMethod),
      );
    }
    if (cashierId != null && cashierId.isNotEmpty) {
      query = query.where('cashierId', isEqualTo: cashierId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: _saleStatusToString(status));
    }

    return query.snapshots().map(
      (s) => s.docs.map((d) => SaleEntity.fromFirestore(d)).toList(),
    );
  }

  /// Aggregate sales summary for a date range.
  Future<Map<String, dynamic>> getSalesSummary({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('sales')
        .where(
          'saleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final sales = snap.docs.map((d) => SaleEntity.fromFirestore(d)).toList();
    final totalRevenue = sales.fold(0.0, (s, e) => s + e.finalAmount);
    final paymentCounts = <String, int>{};
    for (final s in sales) {
      final key = _paymentMethodToString(s.paymentMethod);
      paymentCounts[key] = (paymentCounts[key] ?? 0) + 1;
    }
    return {
      'totalRevenue': totalRevenue,
      'totalTransactions': sales.length,
      'averageSale': sales.isEmpty ? 0.0 : totalRevenue / sales.length,
      'paymentMethodCounts': paymentCounts,
    };
  }

  String _paymentMethodToString(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.momo:
        return 'momo';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bankTransfer:
        return 'bankTransfer';
      case PaymentMethod.credit:
        return 'credit';
    }
  }

  String _saleStatusToString(SaleStatus s) {
    switch (s) {
      case SaleStatus.completed:
        return 'completed';
      case SaleStatus.pending:
        return 'pending';
      case SaleStatus.refunded:
        return 'refunded';
      case SaleStatus.cancelled:
        return 'cancelled';
    }
  }
}

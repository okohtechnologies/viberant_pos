// lib/data/repositories/dashboard_repository.dart
// FIX: getDashboardStats() now listens ONLY to today's sales instead of
// firing _calculateRealTimeStats() on every businesses/{id} doc write.
// This reduces unbounded collection reads to a scoped daily query.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_entity.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<DashboardStats> getDashboardStats(String businessId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Listen ONLY to today's sales — not the entire businesses/{id} doc.
    // This fires only when today's sales change, not on every Firestore write.
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('sales')
        .where(
          'saleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .orderBy('saleDate', descending: true)
        .snapshots()
        .asyncMap(
          (todaySnap) =>
              _buildStats(businessId: businessId, todayDocs: todaySnap.docs),
        );
  }

  Future<DashboardStats> _buildStats({
    required String businessId,
    required List<QueryDocumentSnapshot> todayDocs,
  }) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = now.subtract(const Duration(days: 30));

      // Products count — lightweight, one-time fetch (not a stream)
      final productsSnap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      final totalProducts = productsSnap.size;
      final lowStockItems = productsSnap.docs
          .where(
            (d) => (d['stock'] ?? 0) as num <= ((d['minStock'] ?? 5) as num),
          )
          .length;

      // Customers count
      final customersSnap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('customers')
          .count()
          .get();
      final totalCustomers = customersSnap.count ?? 0;

      // Today stats (from the live snapshot passed in)
      final todayRevenue = todayDocs.fold<double>(
        0.0,
        (sum, d) => sum + ((d['finalAmount'] ?? 0.0) as num).toDouble(),
      );

      // Weekly / monthly — fetched once per stream emission
      // (only runs when today's sales change, which is reasonable)
      final weeklySalesSnap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where(
            'saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
          )
          .get();

      final monthlySalesSnap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where(
            'saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .get();

      final weeklyRevenue = _sumRevenue(weeklySalesSnap.docs);
      final monthlyRevenue = _sumRevenue(monthlySalesSnap.docs);

      final weeklyChart = _weeklyChartData(weeklySalesSnap.docs);
      final monthlyChart = _monthlyChartData(monthlySalesSnap.docs);

      // Recent sales from today's docs (already ordered desc)
      final recentSales = todayDocs.take(5).map(_toRecentSale).toList();

      return DashboardStats(
        todayRevenue: todayRevenue,
        todaySales: todayDocs.length,
        totalProducts: totalProducts,
        totalCustomers: totalCustomers,
        lowStockItems: lowStockItems,
        weeklyRevenue: weeklyRevenue,
        monthlyRevenue: monthlyRevenue,
        weeklySales: weeklyChart,
        monthlySales: monthlyChart,
        recentSales: recentSales,
      );
    } catch (e) {
      debugPrint('Error building dashboard stats: $e');
      return DashboardStats.empty();
    }
  }

  double _sumRevenue(List<QueryDocumentSnapshot> docs) => docs.fold(
    0.0,
    (s, d) => s + ((d['finalAmount'] ?? 0.0) as num).toDouble(),
  );

  List<SaleChartData> _weeklyChartData(List<QueryDocumentSnapshot> docs) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final rev = {for (final d in days) d: 0.0};
    for (final doc in docs) {
      final date = (doc['saleDate'] as Timestamp).toDate();
      final day = days[date.weekday - 1];
      rev[day] =
          (rev[day] ?? 0) + ((doc['finalAmount'] ?? 0.0) as num).toDouble();
    }
    return days
        .map((d) => SaleChartData(period: d, revenue: rev[d]!, salesCount: 0))
        .toList();
  }

  List<SaleChartData> _monthlyChartData(List<QueryDocumentSnapshot> docs) {
    const weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
    final rev = {for (final w in weeks) w: 0.0};
    for (final doc in docs) {
      final date = (doc['saleDate'] as Timestamp).toDate();
      final first = DateTime(date.year, date.month, 1);
      final week = 'Week ${((date.day + first.weekday - 1) ~/ 7) + 1}';
      if (rev.containsKey(week)) {
        rev[week] =
            (rev[week] ?? 0) + ((doc['finalAmount'] ?? 0.0) as num).toDouble();
      }
    }
    return weeks
        .map((w) => SaleChartData(period: w, revenue: rev[w]!, salesCount: 0))
        .toList();
  }

  RecentSale _toRecentSale(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecentSale(
      id: doc.id,
      customerName: (data['customerName'] as String?)?.isNotEmpty == true
          ? data['customerName'] as String
          : 'Walk-in Customer',
      amount: ((data['finalAmount'] ?? 0.0) as num).toDouble(),
      date: (data['saleDate'] as Timestamp).toDate(),
      itemsCount: (data['items'] as List).length,
    );
  }
}

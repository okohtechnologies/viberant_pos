import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_entity.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;
  DashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fixed: Listens only to TODAY's sales, not all sales.
  /// Avoids fetching unbounded collections on every write.
  Stream<DashboardStats> getDashboardStats(String businessId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

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
        .asyncMap((todaySnap) => _buildStats(businessId, todaySnap, now));
  }

  Future<DashboardStats> _buildStats(
    String businessId,
    QuerySnapshot todaySnap,
    DateTime now,
  ) async {
    try {
      // Today's metrics from the already-fetched snapshot
      final todaySales = todaySnap.docs;
      final todayRevenue = todaySales.fold(
        0.0,
        (s, d) =>
            s + ((d.data() as Map)['finalAmount'] as num? ?? 0).toDouble(),
      );

      // Fetch weekly sales (last 7 days) as a lightweight query
      final weekStart = now.subtract(const Duration(days: 7));
      final weekSnap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where(
            'saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
          )
          .get();

      final weeklyRevenue = weekSnap.docs.fold(
        0.0,
        (s, d) => s + ((d.data())['finalAmount'] as num? ?? 0).toDouble(),
      );

      final weeklySales = _buildWeeklyChart(weekSnap.docs, weekStart, now);
      final recentSales = _buildRecentSales(todaySales.take(5).toList());

      // Products count (lightweight — no stream)
      final productsSnap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      final totalProducts = productsSnap.size;
      final lowStockItems = productsSnap.docs
          .where((d) => (d['stock'] ?? 0) <= (d['minStock'] ?? 5))
          .length;

      return DashboardStats(
        todayRevenue: todayRevenue,
        todaySales: todaySales.length,
        totalProducts: totalProducts,
        totalCustomers: 0,
        lowStockItems: lowStockItems,
        weeklyRevenue: weeklyRevenue,
        monthlyRevenue: weeklyRevenue,
        weeklySales: weeklySales,
        monthlySales: weeklySales,
        recentSales: recentSales,
      );
    } catch (e) {
      debugPrint('❌ Dashboard stats error: $e');
      return DashboardStats.empty();
    }
  }

  List<SaleChartData> _buildWeeklyChart(
    List<QueryDocumentSnapshot> docs,
    DateTime start,
    DateTime end,
  ) {
    final days = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final d = end.subtract(Duration(days: i));
      days['${d.month}/${d.day}'] = 0;
    }
    for (final doc in docs) {
      final data = doc.data() as Map;
      final date = (data['saleDate'] as Timestamp?)?.toDate();
      if (date == null) continue;
      final key = '${date.month}/${date.day}';
      days[key] =
          (days[key] ?? 0) + ((data['finalAmount'] as num?)?.toDouble() ?? 0);
    }
    return days.entries
        .map(
          (e) => SaleChartData(period: e.key, revenue: e.value, salesCount: 0),
        )
        .toList();
  }

  List<RecentSale> _buildRecentSales(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return RecentSale(
        id: doc.id,
        customerName: (data['customerName'] as String?)?.isNotEmpty == true
            ? data['customerName'] as String
            : 'Walk-in',
        amount: (data['finalAmount'] as num?)?.toDouble() ?? 0,
        date: (data['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        itemsCount: (data['items'] as List?)?.length ?? 0,
      );
    }).toList();
  }
}

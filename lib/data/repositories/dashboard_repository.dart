// lib/data/repositories/dashboard_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dashboard_entity.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<DashboardStats> getDashboardStats(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .snapshots()
        .asyncMap((_) => _calculateRealTimeStats(businessId));
  }

  Future<DashboardStats> _calculateRealTimeStats(String businessId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = now.subtract(const Duration(days: 30));

      // Get sales data
      final salesSnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .get();

      final allSales = salesSnapshot.docs;

      // Calculate today's stats
      final todaySales = allSales.where((doc) {
        final saleDate = (doc['saleDate'] as Timestamp).toDate();
        return saleDate.isAfter(todayStart);
      }).toList();

      final todayRevenue = _calculateTotalRevenue(todaySales);

      // Calculate weekly stats
      final weeklySales = allSales.where((doc) {
        final saleDate = (doc['saleDate'] as Timestamp).toDate();
        return saleDate.isAfter(weekStart);
      }).toList();

      final weeklyRevenue = _calculateTotalRevenue(weeklySales);
      final weeklyChartData = _generateWeeklyChartData(weeklySales);

      // Calculate monthly stats
      final monthlySales = allSales.where((doc) {
        final saleDate = (doc['saleDate'] as Timestamp).toDate();
        return saleDate.isAfter(monthStart);
      }).toList();

      final monthlyRevenue = _calculateTotalRevenue(monthlySales);
      final monthlyChartData = _generateMonthlyChartData(monthlySales);

      // Get products data
      final productsSnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      final totalProducts = productsSnapshot.size;
      final lowStockItems = productsSnapshot.docs
          .where((doc) => (doc['stock'] ?? 0) <= (doc['minStock'] ?? 5))
          .length;

      // Get customers data
      final customersSnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('customers')
          .get();

      final totalCustomers = customersSnapshot.size;

      // Get recent sales (last 5)
      final recentSalesData = allSales
          .take(5)
          .map((doc) => _documentToRecentSale(doc))
          .toList();

      return DashboardStats(
        todayRevenue: todayRevenue,
        todaySales: todaySales.length,
        totalProducts: totalProducts,
        totalCustomers: totalCustomers,
        lowStockItems: lowStockItems,
        weeklyRevenue: weeklyRevenue,
        monthlyRevenue: monthlyRevenue,
        weeklySales: weeklyChartData,
        monthlySales: monthlyChartData,
        recentSales: recentSalesData,
      );
    } catch (e) {
      print('Error calculating dashboard stats: $e');
      return DashboardStats.empty();
    }
  }

  double _calculateTotalRevenue(List<QueryDocumentSnapshot> sales) {
    return sales.fold(0.0, (sum, doc) {
      return sum + (doc['finalAmount'] ?? 0.0).toDouble();
    });
  }

  List<SaleChartData> _generateWeeklyChartData(
    List<QueryDocumentSnapshot> weeklySales,
  ) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dailyRevenue = {for (var day in days) day: 0.0};

    for (final sale in weeklySales) {
      final saleDate = (sale['saleDate'] as Timestamp).toDate();
      final dayName = _getDayName(saleDate);
      final amount = (sale['finalAmount'] ?? 0.0).toDouble();
      dailyRevenue[dayName] = (dailyRevenue[dayName] ?? 0) + amount;
    }

    return days
        .map(
          (day) => SaleChartData(
            period: day,
            revenue: dailyRevenue[day]!,
            salesCount: 0, // You can calculate this if needed
          ),
        )
        .toList();
  }

  List<SaleChartData> _generateMonthlyChartData(
    List<QueryDocumentSnapshot> monthlySales,
  ) {
    final weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
    final weeklyRevenue = {
      'Week 1': 0.0,
      'Week 2': 0.0,
      'Week 3': 0.0,
      'Week 4': 0.0,
    };

    for (final sale in monthlySales) {
      final saleDate = (sale['saleDate'] as Timestamp).toDate();
      final week = _getWeekOfMonth(saleDate);
      final amount = (sale['finalAmount'] ?? 0.0).toDouble();
      weeklyRevenue['Week $week'] = (weeklyRevenue['Week $week'] ?? 0) + amount;
    }

    return weeks
        .map(
          (week) => SaleChartData(
            period: week,
            revenue: weeklyRevenue[week]!,
            salesCount: 0,
          ),
        )
        .toList();
  }

  RecentSale _documentToRecentSale(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecentSale(
      id: doc.id,
      customerName: data['customerName'] ?? 'Walk-in Customer',
      amount: (data['finalAmount'] ?? 0.0).toDouble(),
      date: (data['saleDate'] as Timestamp).toDate(),
      itemsCount: (data['items'] as List).length,
    );
  }

  String _getDayName(DateTime date) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final firstDayWeekday = firstDay.weekday;
    final dayOfMonth = date.day;
    return ((dayOfMonth + firstDayWeekday - 1) ~/ 7) + 1;
  }
}

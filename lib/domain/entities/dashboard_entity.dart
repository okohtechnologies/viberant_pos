// lib/domain/entities/dashboard_entity.dart
class DashboardStats {
  final double todayRevenue;
  final int todaySales;
  final int totalProducts;
  final int totalCustomers;
  final int lowStockItems;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final List<SaleChartData> weeklySales;
  final List<SaleChartData> monthlySales;
  final List<RecentSale> recentSales;

  const DashboardStats({
    required this.todayRevenue,
    required this.todaySales,
    required this.totalProducts,
    required this.totalCustomers,
    required this.lowStockItems,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.weeklySales,
    required this.monthlySales,
    required this.recentSales,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      todayRevenue: 0,
      todaySales: 0,
      totalProducts: 0,
      totalCustomers: 0,
      lowStockItems: 0,
      weeklyRevenue: 0,
      monthlyRevenue: 0,
      weeklySales: [],
      monthlySales: [],
      recentSales: [],
    );
  }
}

class SaleChartData {
  final String period;
  final double revenue;
  final int salesCount;

  const SaleChartData({
    required this.period,
    required this.revenue,
    required this.salesCount,
  });
}

class RecentSale {
  final String id;
  final String customerName;
  final double amount;
  final DateTime date;
  final int itemsCount;

  const RecentSale({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.itemsCount,
  });
}

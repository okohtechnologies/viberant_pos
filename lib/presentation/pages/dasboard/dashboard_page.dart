// lib/presentation/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
// ignore: unused_import
import 'package:viberant_pos/presentation/pages/orders/order_history.dart';
import 'package:viberant_pos/presentation/providers/reports/sales_report_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/dashboard_entity.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../pages/admin/users_management_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _DashboardHeader(authState: authState, isAdmin: isAdmin),

              const SizedBox(height: 24),

              // Stats Grid
              Expanded(
                flex: 2,
                child: dashboardStats.when(
                  loading: () => _buildLoadingStats(),
                  error: (error, stack) => _buildErrorState(error),
                  data: (stats) => _StatsGrid(stats: stats),
                ),
              ),

              const SizedBox(height: 24),

              // Charts Section
              Expanded(
                flex: 3,
                child: dashboardStats.when(
                  loading: () => _buildLoadingChart(),
                  error: (error, stack) => _buildChartError(error),
                  data: (stats) => _ChartsSection(stats: stats),
                ),
              ),

              const SizedBox(height: 24),

              // Admin Tools Button (only for admins) OR Recent Activity
              if (isAdmin)
                _AdminToolsButton()
              else
                Expanded(
                  flex: 2,
                  child: dashboardStats.when(
                    loading: () => _buildLoadingRecent(),
                    error: (error, stack) => _buildRecentError(error),
                    data: (stats) => _RecentActivity(stats: stats),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: List.generate(4, (index) => _ShimmerStatCard()),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLoadingRecent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerText(width: 150),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: 4,
            itemBuilder: (context, index) => _ShimmerRecentItem(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: ViberantColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: GoogleFonts.inter(color: ViberantColors.error),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GoogleFonts.inter(fontSize: 12, color: ViberantColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartError(Object error) {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 48,
              color: ViberantColors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'Chart unavailable',
              style: GoogleFonts.inter(color: ViberantColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentError(Object error) {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_rounded, size: 48, color: ViberantColors.grey),
            const SizedBox(height: 8),
            Text(
              'Unable to load recent sales',
              style: GoogleFonts.inter(color: ViberantColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Updated Dashboard Header with Admin Badge
class _DashboardHeader extends StatelessWidget {
  final AuthState authState;
  final bool isAdmin;

  const _DashboardHeader({required this.authState, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    String userName = 'User';

    if (authState is AuthAuthenticated) {
      final user = (authState as AuthAuthenticated).user;
      userName = user.displayName;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Welcome back, $userName',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: ViberantColors.grey,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ViberantColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ADMIN',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ViberantColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: ViberantColors.onSurface,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ViberantColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.analytics_rounded,
            color: ViberantColors.primary,
            size: 24,
          ),
        ),
      ],
    );
  }
}

// Admin Tools Button
class _AdminToolsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ViberantColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: ViberantColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Tools',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ViberantColors.onSurface,
                      ),
                    ),
                    Text(
                      'Manage users, products, and business settings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ViberantColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ViberantColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ADMIN',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ViberantColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAdminToolsModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: ViberantColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Open Admin Tools',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminToolsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdminToolsModal(),
    );
  }
}

// Admin Tools Modal Bottom Sheet - Updated to ConsumerWidget
class _AdminToolsModal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ViberantColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: ViberantColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Admin Tools',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ViberantColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your business operations',
            style: GoogleFonts.inter(fontSize: 14, color: ViberantColors.grey),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              _AdminToolCard(
                title: 'Manage Users',
                icon: Icons.people_rounded,
                color: ViberantColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsersManagementPage(),
                    ),
                  );
                },
                description: 'Add staff members',
              ),
              _AdminToolCard(
                title: 'Reports',
                icon: Icons.analytics_rounded,
                color: ViberantColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  final authState = ref.read(authProvider);

                  if (authState is AuthAuthenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SalesReportScreen(
                          businessId: authState.user.businessId,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please login to view reports'),
                        backgroundColor: ViberantColors.error,
                      ),
                    );
                  }
                },
                description: 'View sales analytics',
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close ❌',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ViberantColors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Admin Tool Card for Modal
class _AdminToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String description;

  const _AdminToolCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ViberantColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ViberantColors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: ViberantColors.grey,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ViberantColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ViberantColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stats Grid
class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _StatCard(
          title: "Today's Revenue",
          value: 'GHS ${NumberFormat('#,###.00').format(stats.todayRevenue)}',
          icon: Icons.attach_money_rounded,
          color: ViberantColors.success,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

        _StatCard(
          title: "Today's Sales",
          value: stats.todaySales.toString(),
          icon: Icons.shopping_cart_rounded,
          color: ViberantColors.primary,
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),

        _StatCard(
          title: "Total Products",
          value: stats.totalProducts.toString(),
          icon: Icons.inventory_2_rounded,
          color: ViberantColors.warning,
          trend: null,
        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

        _StatCard(
          title: "Low Stock",
          value: stats.lowStockItems.toString(),
          icon: Icons.warning_rounded,
          color: ViberantColors.error,
          trend: stats.lowStockItems > 0 ? 'Alert!' : null,
        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
      ],
    );
  }
}

// Individual Stat Card
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trend!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ViberantColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ViberantColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Charts Section
class _ChartsSection extends StatelessWidget {
  final DashboardStats stats;

  const _ChartsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Weekly Revenue Chart
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: ViberantColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Revenue',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ViberantColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'GHS ${NumberFormat('#,###.00').format(stats.weeklyRevenue)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ViberantColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: stats.weeklySales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                size: 48,
                                color: ViberantColors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No sales data available',
                                style: GoogleFonts.inter(
                                  color: ViberantColors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SfCartesianChart(
                          primaryXAxis: CategoryAxis(
                            labelStyle: GoogleFonts.inter(fontSize: 10),
                          ),
                          primaryYAxis: NumericAxis(
                            labelStyle: GoogleFonts.inter(fontSize: 10),
                            numberFormat: NumberFormat.currency(symbol: 'GHS '),
                          ),
                          series: <CartesianSeries>[
                            ColumnSeries<SaleChartData, String>(
                              dataSource: stats.weeklySales,
                              xValueMapper: (SaleChartData sales, _) =>
                                  sales.period,
                              yValueMapper: (SaleChartData sales, _) =>
                                  sales.revenue,
                              color: ViberantColors.primary,
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                labelAlignment: ChartDataLabelAlignment.outer,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Recent Activity
class _RecentActivity extends StatelessWidget {
  final DashboardStats stats;

  const _RecentActivity({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Sales',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ViberantColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: stats.recentSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_rounded,
                          size: 48,
                          color: ViberantColors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent sales',
                          style: GoogleFonts.inter(color: ViberantColors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: stats.recentSales.length,
                    itemBuilder: (context, index) {
                      final sale = stats.recentSales[index];
                      return _RecentSaleItem(sale: sale)
                          .animate()
                          .fadeIn(delay: (index * 100).ms)
                          .slideY(begin: 0.1);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Recent Sale Item
class _RecentSaleItem extends StatelessWidget {
  final RecentSale sale;

  const _RecentSaleItem({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ViberantColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ViberantColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.receipt_rounded,
              color: ViberantColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customerName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ViberantColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sale.itemsCount} items • ${_formatTime(sale.date)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ViberantColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'GHS ${NumberFormat('#,###.00').format(sale.amount)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ViberantColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

// Shimmer Loading Widgets
class _ShimmerStatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ViberantColors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ViberantColors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: ViberantColors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ViberantColors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerText extends StatelessWidget {
  final double width;

  const _ShimmerText({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: ViberantColors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ShimmerRecentItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ViberantColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ViberantColors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: ViberantColors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: ViberantColors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: ViberantColors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

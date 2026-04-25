import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/dashboard_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/viberant_card.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/widgets.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
    final userName = authState is AuthAuthenticated
        ? authState.user.displayName.split(' ').first
        : 'there';
    final isMobile = Breakpoints.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _DashboardHeader(userName: userName, isAdmin: isAdmin),
          const SizedBox(height: 24),

          // ── KPI Stats Grid ───────────────────────────────────────────────────
          stats.when(
            loading: () =>
                ShimmerGrid(count: 4, crossAxisCount: isMobile ? 2 : 4),
            error: (e, _) => _ErrorBlock(message: e.toString()),
            data: (s) => _StatsGrid(stats: s, isMobile: isMobile),
          ),
          const SizedBox(height: 24),

          // ── Weekly Revenue Chart ─────────────────────────────────────────────
          stats.when(
            loading: () => const ShimmerCard(height: 220),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => _WeeklyChart(stats: s).animate().fadeIn(delay: 200.ms),
          ),
          const SizedBox(height: 24),

          // ── Admin Tools OR Recent Sales ──────────────────────────────────────
          if (isAdmin)
            _AdminToolsCard(ref: ref).animate().fadeIn(delay: 300.ms)
          else
            stats.when(
              loading: () => const ShimmerList(count: 4, itemHeight: 68),
              error: (_, __) => const SizedBox.shrink(),
              data: (s) =>
                  _RecentSalesList(stats: s).animate().fadeIn(delay: 300.ms),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final String userName;
  final bool isAdmin;
  const _DashboardHeader({required this.userName, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
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
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  StatusChip.role(true),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ViberantColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: ViberantColors.primary,
            size: 24,
          ),
        ),
      ],
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  final bool isMobile;
  const _StatsGrid({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###.00');
    final cols = isMobile ? 2 : 4;

    final cards = [
      StatCard(
        title: "Today's Revenue",
        value: 'GHS ${currency.format(stats.todayRevenue)}',
        icon: Icons.trending_up_rounded,
        color: ViberantColors.success,
      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
      StatCard(
        title: "Today's Sales",
        value: stats.todaySales.toString(),
        icon: Icons.shopping_cart_rounded,
        color: ViberantColors.primary,
      ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
      StatCard(
        title: 'Total Products',
        value: stats.totalProducts.toString(),
        icon: Icons.inventory_2_rounded,
        color: ViberantColors.warning,
      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05),
      StatCard(
        title: 'Low Stock',
        value: stats.lowStockItems.toString(),
        icon: Icons.warning_amber_rounded,
        color: ViberantColors.error,
        badge: stats.lowStockItems > 0 ? 'ALERT' : null,
      ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => cards[i],
    );
  }
}

// ─── Weekly Chart ─────────────────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final DashboardStats stats;
  const _WeeklyChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###.00');
    return ViberantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Revenue',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'GHS ${currency.format(stats.weeklyRevenue)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ViberantColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ViberantColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: ViberantColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: stats.weeklySales.isEmpty
                ? EmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'No sales this week',
                    description: 'Start selling to see revenue data',
                  )
                : SfCartesianChart(
                    margin: EdgeInsets.zero,
                    plotAreaBorderWidth: 0,
                    primaryXAxis: CategoryAxis(
                      labelStyle: GoogleFonts.inter(
                        fontSize: 10,
                        color: ViberantColors.outline,
                      ),
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: const AxisLine(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      labelStyle: GoogleFonts.inter(
                        fontSize: 9,
                        color: ViberantColors.outline,
                      ),
                      labelFormat: 'GHS {value}',
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(size: 0),
                    ),
                    series: <CartesianSeries>[
                      ColumnSeries<SaleChartData, String>(
                        dataSource: stats.weeklySales,
                        xValueMapper: (d, _) => d.period,
                        yValueMapper: (d, _) => d.revenue,
                        color: ViberantColors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          textStyle: GoogleFonts.inter(
                            fontSize: 9,
                            color: ViberantColors.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Admin Tools Card ─────────────────────────────────────────────────────────
class _AdminToolsCard extends StatelessWidget {
  final WidgetRef ref;
  const _AdminToolsCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    return ViberantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ViberantColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Manage users, reports, and business settings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ViberantColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip.role(true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AdminAction(
                  title: 'Manage Users',
                  icon: Icons.people_rounded,
                  color: ViberantColors.primary,
                  onTap: () => AppNavigator.toUsersManagement(context, ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AdminAction(
                  title: 'Sales Reports',
                  icon: Icons.analytics_rounded,
                  color: ViberantColors.warning,
                  onTap: () => AppNavigator.toSalesReport(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AdminAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ViberantCard(
      color: color.withOpacity(0.06),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
        ],
      ),
    );
  }
}

// ─── Recent Sales List ────────────────────────────────────────────────────────
class _RecentSalesList extends StatelessWidget {
  final DashboardStats stats;
  const _RecentSalesList({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ViberantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Recent Sales'),
          const SizedBox(height: 12),
          if (stats.recentSales.isEmpty)
            EmptyState(
              icon: Icons.receipt_rounded,
              title: 'No sales yet',
              description: 'Complete a sale to see it here',
            )
          else
            ...stats.recentSales.asMap().entries.map(
              (e) => _RecentSaleRow(
                sale: e.value,
              ).animate().fadeIn(delay: (e.key * 80).ms).slideY(begin: 0.05),
            ),
        ],
      ),
    );
  }
}

class _RecentSaleRow extends StatelessWidget {
  final RecentSale sale;
  const _RecentSaleRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTime(sale.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ViberantColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              color: ViberantColors.primary,
              size: 18,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${sale.itemsCount} items · $timeAgo',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ViberantColors.outline,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'GHS ${NumberFormat('#,###.00').format(sale.amount)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ViberantColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  const _ErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: ViberantColors.error, size: 40),
        const SizedBox(height: 8),
        Text(
          'Failed to load dashboard',
          style: GoogleFonts.inter(color: ViberantColors.error),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: GoogleFonts.inter(fontSize: 12, color: ViberantColors.outline),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

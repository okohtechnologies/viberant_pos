// lib/presentation/pages/dasboard/dashboard_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/viberant_card.dart';
import '../../../domain/entities/dashboard_entity.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final currency = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);

    return statsAsync.when(
      loading: () => _LoadingSkeleton(),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Dashboard unavailable',
        description: e.toString(),
      ),
      data: (stats) => _DashboardContent(stats: stats, currency: currency),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardStats stats;
  final NumberFormat currency;

  const _DashboardContent({required this.stats, required this.currency});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPI grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isWide ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 1.2 : 1.1,
            children: [
              StatCard(
                label: "Today's Revenue",
                value: currency.format(stats.todayRevenue),
                icon: Icons.payments_rounded,
                iconColor: ViberantColors.primary,
              ),
              StatCard(
                label: "Today's Sales",
                value: '${stats.todaySales}',
                icon: Icons.point_of_sale_rounded,
                iconColor: ViberantColors.secondary,
              ),
              StatCard(
                label: 'Products',
                value: '${stats.totalProducts}',
                icon: Icons.inventory_2_rounded,
                iconColor: ViberantColors.tertiary,
              ),
              StatCard(
                label: 'Customers',
                value: '${stats.totalCustomers}',
                icon: Icons.people_rounded,
                iconColor: ViberantColors.info,
              ),
            ],
          ),

          // Low stock alert
          if (stats.lowStockItems > 0) ...[
            const SizedBox(height: 16),
            ViberantCard(
              padding: const EdgeInsets.all(16),
              color: ViberantColors.warning.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: ViberantColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${stats.lowStockItems} product${stats.lowStockItems == 1 ? '' : 's'} running low on stock',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    'View',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ViberantColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Weekly chart
          _SectionHeader(title: 'Weekly Revenue'),
          const SizedBox(height: 12),
          ViberantCard(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: SizedBox(
              height: 160,
              child: _WeeklyChart(data: stats.weeklySales),
            ),
          ),

          const SizedBox(height: 20),

          // Recent sales
          _SectionHeader(title: 'Recent Sales'),
          const SizedBox(height: 12),
          if (stats.recentSales.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No sales today',
              description: 'Completed sales will appear here.',
            )
          else
            ViberantCard(
              child: Column(
                children: stats.recentSales
                    .map((s) => _RecentSaleRow(sale: s, currency: currency))
                    .toList(),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _WeeklyChart extends StatelessWidget {
  final List<SaleChartData> data;
  const _WeeklyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.25,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                data[v.toInt()].period,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.revenue,
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                color: scheme.primary,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY * 1.25,
                  color: scheme.surfaceContainerHigh,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RecentSaleRow extends StatelessWidget {
  final RecentSale sale;
  final NumberFormat currency;

  const _RecentSaleRow({required this.sale, required this.currency});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // divider handled by Column's children divider logic

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(ViberantRadius.md),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  size: 16,
                  color: scheme.onPrimaryContainer,
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
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(sale.date) +
                          '  ·  ${sale.itemsCount} item${sale.itemsCount == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(sale.amount),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  StatusChip.success(label: 'Done'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 64),
      ],
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          LoadingShimmer.card(),
          LoadingShimmer.card(),
          LoadingShimmer.card(),
          LoadingShimmer.card(),
        ],
      ),
      const SizedBox(height: 20),
      const LoadingShimmer(height: 200, borderRadius: ViberantRadius.card),
      const SizedBox(height: 20),
      const LoadingShimmer(height: 240, borderRadius: ViberantRadius.card),
    ],
  );
}

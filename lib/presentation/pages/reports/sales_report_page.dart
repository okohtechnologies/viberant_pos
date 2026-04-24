// lib/presentation/pages/reports/sales_report_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../providers/reports/sales_report_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/viberant_card.dart';
import '../../widgets/reports/sales_filter_widget.dart';
import '../../widgets/reports/sales_summary_cards.dart';
import '../orders/sales_details_page.dart';

class SalesReportPage extends ConsumerWidget {
  const SalesReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesReportDataProvider);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          // Filter bar
          const SalesFilterWidget(),

          // Scrollable body
          Expanded(
            child: salesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: LoadingShimmer.card()),
                        SizedBox(width: 12),
                        Expanded(child: LoadingShimmer.card()),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: LoadingShimmer.card()),
                        SizedBox(width: 12),
                        Expanded(child: LoadingShimmer.card()),
                      ],
                    ),
                    SizedBox(height: 20),
                    ShimmerList(count: 6),
                  ],
                ),
              ),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Failed to load report',
                description: e.toString(),
              ),
              data: (sales) =>
                  _ReportBody(sales: sales, summaryAsync: summaryAsync),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final List<SaleEntity> sales;
  final AsyncValue<Map<String, dynamic>> summaryAsync;

  const _ReportBody({required this.sales, required this.summaryAsync});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        summaryAsync.when(
          loading: () => const Column(
            children: [
              Row(
                children: [
                  Expanded(child: LoadingShimmer.card()),
                  SizedBox(width: 12),
                  Expanded(child: LoadingShimmer.card()),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: LoadingShimmer.card()),
                  SizedBox(width: 12),
                  Expanded(child: LoadingShimmer.card()),
                ],
              ),
            ],
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (summary) => SalesSummaryCards(summary: summary),
        ),

        const SizedBox(height: 20),

        // Daily revenue chart
        if (sales.isNotEmpty) ...[
          _SectionLabel('Daily Revenue'),
          const SizedBox(height: 12),
          ViberantCard(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: SizedBox(height: 160, child: _DailyChart(sales: sales)),
          ),
          const SizedBox(height: 20),
        ],

        // Sales list
        _SectionLabel('Transactions (${sales.length})'),
        const SizedBox(height: 12),

        if (sales.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No sales in this period',
            description: 'Adjust the date range or filters above.',
          )
        else
          ViberantCard(
            child: Column(
              children: sales.map((s) => _SaleRow(sale: s)).toList(),
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _DailyChart extends StatelessWidget {
  final List<SaleEntity> sales;
  const _DailyChart({required this.sales});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Aggregate by day
    final dailyMap = <String, double>{};
    for (final s in sales) {
      final key =
          '${s.saleDate.month.toString().padLeft(2, '0')}/${s.saleDate.day.toString().padLeft(2, '0')}';
      dailyMap[key] = (dailyMap[key] ?? 0) + s.finalAmount;
    }

    final entries = dailyMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) return const SizedBox.shrink();

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (entries.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.2,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    'GHS ${s.y.toStringAsFixed(2)}',
                    GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
                .toList(),
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
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: entries.length > 10
                  ? (entries.length / 5).ceilToDouble()
                  : 1,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  entries[idx].key,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: scheme.onSurfaceVariant,
                  ),
                );
              },
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
        lineBarsData: [
          LineChartBarData(
            spots: entries
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                .toList(),
            isCurved: true,
            color: scheme.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: entries.length <= 15,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: scheme.primary,
                strokeWidth: 1.5,
                strokeColor: scheme.surfaceContainerLowest,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.15),
                  scheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final SaleEntity sale;
  const _SaleRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final date = DateFormat('d MMM, hh:mm a').format(sale.saleDate);

    ChipStatus chipStatus;
    switch (sale.status) {
      case SaleStatus.completed:
        chipStatus = ChipStatus.success;
        break;
      case SaleStatus.pending:
        chipStatus = ChipStatus.pending;
        break;
      case SaleStatus.refunded:
        chipStatus = ChipStatus.warning;
        break;
      case SaleStatus.cancelled:
        chipStatus = ChipStatus.error;
        break;
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleDetailsPage(sale: sale)),
      ),
      borderRadius: BorderRadius.circular(ViberantRadius.card),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Method icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(ViberantRadius.md),
                  ),
                  child: Icon(
                    _methodIcon(sale.paymentMethod),
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.customerName?.isNotEmpty == true
                            ? sale.customerName!
                            : 'Walk-in Customer',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        '$date  ·  ${sale.cashierName}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount + status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(sale.finalAmount),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    StatusChip(label: sale.status.name, status: chipStatus),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 66, color: scheme.outlineVariant),
        ],
      ),
    );
  }

  IconData _methodIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.momo:
        return Icons.phone_android_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.credit:
        return Icons.handshake_outlined;
    }
  }
}

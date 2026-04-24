// lib/presentation/pages/sales/today_sales_page.dart
// CHANGED: Replaced raw FirebaseFirestore StreamBuilder with
// ref.watch(todaySalesProvider) from employee_providers.dart.
// No longer requires businessId to be passed in.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../providers/employee_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/viberant_card.dart';
import '../orders/sales_details_page.dart';

class TodaySalesPage extends ConsumerWidget {
  const TodaySalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(todaySalesProvider);
    final scheme = Theme.of(context).colorScheme;
    final currency = NumberFormat('#,###.00');

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          "Today's Sales",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: scheme.onSurface,
          ),
        ),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      body: salesAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LoadingShimmer.card(),
              const SizedBox(height: 16),
              const ShimmerList(count: 6),
            ],
          ),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load sales',
          description: e.toString(),
        ),
        data: (sales) {
          final totalRevenue = sales.fold(
            0.0,
            (s, sale) => s + sale.finalAmount,
          );

          return Column(
            children: [
              // ── Summary strip ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Total Sales',
                        value: '${sales.length}',
                        icon: Icons.point_of_sale_rounded,
                        iconColor: ViberantColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Revenue',
                        value: 'GHS ${currency.format(totalRevenue)}',
                        icon: Icons.payments_rounded,
                        iconColor: ViberantColors.success,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Sales list ──
              if (sales.isEmpty)
                const Expanded(
                  child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No sales today',
                    description:
                        'Sales will appear here as they are processed.',
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _TodaySaleRow(sale: sales[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TodaySaleRow extends StatelessWidget {
  final SaleEntity sale;
  const _TodaySaleRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = DateFormat('hh:mm a').format(sale.saleDate);
    final amount = NumberFormat('#,###.00').format(sale.finalAmount);

    return ViberantCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleDetailsPage(sale: sale)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ViberantColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ViberantRadius.md),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              size: 20,
              color: ViberantColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customerName?.isNotEmpty == true
                      ? sale.customerName!
                      : 'Walk-in Customer',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$time  ·  ${sale.totalItems} item${sale.totalItems == 1 ? '' : 's'}  ·  ${sale.cashierName}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'GHS $amount',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

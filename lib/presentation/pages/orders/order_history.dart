// lib/presentation/pages/orders/order_history.dart
// CHANGED: Replaced raw FirebaseFirestore StreamBuilder with
// ref.watch(myOrderHistoryProvider) from employee_providers.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../providers/employee_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/viberant_card.dart';
import '../orders/sales_details_page.dart';

class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(myOrderHistoryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'My Sales History',
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
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerList(count: 8),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load history',
          description: e.toString(),
        ),
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No sales yet',
              description: 'Your completed sales will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _SaleRow(sale: sales[i]),
          );
        },
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
    final date = DateFormat('d MMM, hh:mm a').format(sale.saleDate);
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(ViberantRadius.md),
            ),
            child: Icon(
              Icons.receipt_rounded,
              size: 18,
              color: scheme.onPrimaryContainer,
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
                  '$date  ·  ${sale.totalItems} item${sale.totalItems == 1 ? '' : 's'}',
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
                'GHS $amount',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              StatusChip.success(label: 'Completed'),
            ],
          ),
        ],
      ),
    );
  }
}

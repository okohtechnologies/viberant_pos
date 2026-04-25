import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/presentation/providers/sale_repository_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../widgets/common/viberant_card.dart';
import '../../widgets/common/widgets.dart';
import '../orders/sales_details_page.dart';

class OrderHistoryPage extends ConsumerWidget {
  final String businessId;
  const OrderHistoryPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Uses Riverpod provider — no raw Firestore in widget
    final ordersAsync = ref.watch(myOrderHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Sales History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const ShimmerList(count: 6, itemHeight: 90),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load history',
          description: e.toString(),
        ),
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No sales yet',
              description: 'Your completed sales will appear here',
            );
          }

          // Summary strip at top
          final totalRevenue = sales.fold(0.0, (s, e) => s + e.finalAmount);

          return Column(
            children: [
              // Summary
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ViberantCard(
                        color: ViberantColors.primary.withOpacity(0.06),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Sales',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: ViberantColors.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${sales.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: ViberantColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ViberantCard(
                        color: ViberantColors.success.withOpacity(0.06),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Revenue',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: ViberantColors.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₵${NumberFormat('#,###.00').format(totalRevenue)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ViberantColors.success,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  itemBuilder: (_, i) => _OrderCard(
                    sale: sales[i],
                  ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.05),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final SaleEntity sale;
  const _OrderCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM · h:mm a').format(sale.saleDate);
    final txnShort = sale.transactionId.length > 12
        ? '${sale.transactionId.substring(0, 12)}…'
        : sale.transactionId;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleDetailsPage(sale: sale)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: ViberantColors.primary.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  txnShort,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ViberantColors.outline,
                  ),
                ),
                StatusChip.fromSaleStatus(sale.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: ViberantColors.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    (sale.customerName?.isNotEmpty == true)
                        ? sale.customerName!
                        : 'Walk-in Customer',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ViberantColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 14,
                  color: ViberantColors.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  '${sale.items.length} items',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ViberantColors.outline,
                  ),
                ),
                const Spacer(),
                Text(
                  '₵${NumberFormat('#,###.00').format(sale.finalAmount)}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ViberantColors.primary,
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

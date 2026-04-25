import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/presentation/providers/sale_repository_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/viberant_card.dart';
import '../../widgets/common/widgets.dart';
import '../orders/sales_details_page.dart';

class TodaySalesPage extends ConsumerWidget {
  final String businessId;
  const TodaySalesPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(todaySalesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Today's Sales",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: salesAsync.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 90),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load sales',
          description: e.toString(),
        ),
        data: (sales) {
          final revenue = sales.fold(0.0, (s, e) => s + e.finalAmount);

          return Column(
            children: [
              // Summary card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ViberantCard(
                  color: ViberantColors.primary.withOpacity(0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ViberantColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.today_rounded,
                              color: ViberantColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Today's Summary",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Revenue',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: ViberantColors.outline,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₵${NumberFormat('#,###.00').format(revenue)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: ViberantColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transactions',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: ViberantColors.outline,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sales.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: ViberantColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ),

              const SizedBox(height: 8),

              // Sales list
              Expanded(
                child: sales.isEmpty
                    ? const EmptyState(
                        icon: Icons.today_rounded,
                        title: 'No sales today',
                        description: 'Completed sales will appear here',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sales.length,
                        itemBuilder: (_, i) {
                          final sale = sales[i];
                          final date = DateFormat(
                            'h:mm a',
                          ).format(sale.saleDate);
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SaleDetailsPage(sale: sale),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
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
                                    color: ViberantColors.primary.withOpacity(
                                      0.03,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: ViberantColors.primary.withOpacity(
                                        0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_rounded,
                                      color: ViberantColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (sale.customerName?.isNotEmpty ==
                                                  true)
                                              ? sale.customerName!
                                              : 'Walk-in Customer',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          '${sale.items.length} items · $date',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: ViberantColors.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₵${NumberFormat('#,###.00').format(sale.finalAmount)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: ViberantColors.primary,
                                        ),
                                      ),
                                      StatusChip.fromSaleStatus(sale.status),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (i * 40).ms),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

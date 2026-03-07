// lib/presentation/widgets/reports/sales_summary_cards.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/presentation/providers/reports/sales_report_provider.dart';
import '../../../core/theme/app_theme.dart';

class SalesSummaryCards extends ConsumerWidget {
  const SalesSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(salesSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        final currencyFormat = NumberFormat.currency(symbol: 'GHS ');

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSummaryCard(
              context,
              title: 'Total Revenue',
              value: currencyFormat.format(summary['totalRevenue'] ?? 0),
              icon: Icons.attach_money_rounded,
              color: ViberantColors.primary,
            ),
            _buildSummaryCard(
              context,
              title: 'Transactions',
              value: '${summary['totalTransactions'] ?? 0}',
              icon: Icons.receipt_rounded,
              color: ViberantColors.secondary,
            ),
            _buildSummaryCard(
              context,
              title: 'Items Sold',
              value: '${summary['totalItemsSold'] ?? 0}',
              icon: Icons.shopping_cart_rounded,
              color: ViberantColors.accent,
            ),
            _buildSummaryCard(
              context,
              title: 'Average Sale',
              value: currencyFormat.format(summary['averageSale'] ?? 0),
              icon: Icons.trending_up_rounded,
              color: ViberantColors.success,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: ViberantColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

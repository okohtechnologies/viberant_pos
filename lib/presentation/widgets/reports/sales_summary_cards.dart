// lib/presentation/widgets/reports/sales_summary_cards.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../common/viberant_card.dart';

class SalesSummaryCards extends StatelessWidget {
  final Map<String, dynamic> summary;

  const SalesSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final success = summary['success'] as bool? ?? false;

    if (!success) return const SizedBox.shrink();

    final totalRevenue = (summary['totalRevenue'] as num?)?.toDouble() ?? 0;
    final totalTransactions =
        (summary['totalTransactions'] as num?)?.toInt() ?? 0;
    final totalItemsSold = (summary['totalItemsSold'] as num?)?.toInt() ?? 0;
    final averageSale = (summary['averageSale'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Total Revenue',
                value: currency.format(totalRevenue),
                icon: Icons.payments_rounded,
                color: ViberantColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'Transactions',
                value: '$totalTransactions',
                icon: Icons.receipt_long_rounded,
                color: ViberantColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Items Sold',
                value: '$totalItemsSold',
                icon: Icons.shopping_bag_rounded,
                color: ViberantColors.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'Avg. Sale',
                value: currency.format(averageSale),
                icon: Icons.trending_up_rounded,
                color: ViberantColors.info,
              ),
            ),
          ],
        ),

        // Payment method breakdown
        if ((summary['paymentMethodCounts'] as Map?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          ViberantCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Methods',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...(summary['paymentMethodCounts'] as Map<String, dynamic>)
                    .entries
                    .map(
                      (e) => _PaymentMethodRow(
                        method: e.key,
                        count: e.value as int,
                        total: totalTransactions,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ViberantCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ViberantRadius.md),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final String method;
  final int count;
  final int total;

  const _PaymentMethodRow({
    required this.method,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = total > 0 ? count / total : 0.0;
    final label = _label(method);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                '$count  (${(pct * 100).toStringAsFixed(0)}%)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHigh,
              color: ViberantColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _label(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'momo':
        return 'Mobile Money';
      case 'card':
        return 'Card';
      case 'banktransfer':
        return 'Bank Transfer';
      case 'credit':
        return 'Credit';
      default:
        return method;
    }
  }
}

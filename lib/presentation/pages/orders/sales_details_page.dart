import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/cart_item_entity.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/viberant_card.dart';
import '../../widgets/common/widgets.dart';

class SaleDetailsPage extends ConsumerWidget {
  final SaleEntity sale;
  const SaleDetailsPage({super.key, required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
    final fmt = NumberFormat('#,###.00');
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');

    double totalCost = 0;
    double totalProfit = 0;
    if (isAdmin) {
      for (final item in sale.items) {
        totalCost += item.product.costPrice * item.quantity;
        totalProfit +=
            (item.product.price - item.product.costPrice) * item.quantity;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Sale Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Receipt',
            onPressed: () =>
                ReceiptService.generateAndShareReceipt(sale, context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Summary card ──────────────────────────────────────────────────
            ViberantCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Receipt Details',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      StatusChip.fromSaleStatus(sale.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    'Transaction ID',
                    sale.transactionId,
                    copyable: true,
                  ),
                  _InfoRow('Date', dateFmt.format(sale.saleDate)),
                  _InfoRow('Cashier', sale.cashierName),
                  _InfoRow(
                    'Customer',
                    (sale.customerName?.isNotEmpty == true)
                        ? sale.customerName!
                        : 'Walk-in Customer',
                  ),
                  const SizedBox(height: 12),
                  // Payment method badge
                  Row(
                    children: [
                      Icon(
                        _paymentIcon(sale.paymentMethod),
                        size: 18,
                        color: _paymentColor(sale.paymentMethod),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _paymentLabel(sale.paymentMethod),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _paymentColor(sale.paymentMethod),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 50.ms),

            const SizedBox(height: 14),

            // ── Items card ────────────────────────────────────────────────────
            ViberantCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Items Purchased'),
                  const SizedBox(height: 12),
                  ...sale.items.asMap().entries.map(
                    (e) => _ItemRow(
                      item: e.value,
                      number: e.key + 1,
                      isAdmin: isAdmin,
                      isLast: e.key == sale.items.length - 1,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 14),

            // ── Totals card ───────────────────────────────────────────────────
            ViberantCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Payment Summary'),
                  const SizedBox(height: 12),
                  _TotalRow('Subtotal', sale.totalAmount),
                  const SizedBox(height: 6),
                  _TotalRow('Tax', sale.taxAmount),
                  if (sale.discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    _TotalRow(
                      'Discount',
                      -sale.discountAmount,
                      color: ViberantColors.success,
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '₵${fmt.format(sale.finalAmount)}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: ViberantColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),

            // ── Admin profit card ─────────────────────────────────────────────
            if (isAdmin) ...[
              const SizedBox(height: 14),
              ViberantCard(
                color: ViberantColors.primary.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          color: ViberantColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Profit Analysis',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip.role(true),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _ProfitMetric(
                          label: 'Revenue',
                          value: sale.finalAmount,
                          color: ViberantColors.primary,
                        ),
                        _ProfitMetric(
                          label: 'Cost',
                          value: totalCost,
                          color: ViberantColors.outline,
                        ),
                        _ProfitMetric(
                          label: 'Profit',
                          value: totalProfit,
                          color: totalProfit >= 0
                              ? ViberantColors.success
                              : ViberantColors.error,
                        ),
                      ],
                    ),
                    if (totalCost > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Margin: ${((totalProfit / sale.finalAmount) * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: ViberantColors.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],

            const SizedBox(height: 20),

            // ── Share receipt button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    ReceiptService.generateAndShareReceipt(sale, context),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Receipt'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.momo:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card Payment';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  IconData _paymentIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.momo:
        return Icons.phone_android_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.credit:
        return Icons.receipt_long_rounded;
    }
  }

  Color _paymentColor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return ViberantColors.success;
      case PaymentMethod.momo:
        return ViberantColors.primary;
      case PaymentMethod.card:
        return ViberantColors.warning;
      case PaymentMethod.bankTransfer:
        return ViberantColors.info;
      case PaymentMethod.credit:
        return ViberantColors.error;
    }
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _InfoRow(this.label, this.value, {this.copyable = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: ViberantColors.outline),
        ),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (copyable)
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: value)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: ViberantColors.outline,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

// ─── Total row ────────────────────────────────────────────────────────────────
class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  const _TotalRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 13, color: ViberantColors.outline),
      ),
      Text(
        '₵${NumberFormat('#,###.00').format(value.abs())}',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ],
  );
}

// ─── Item row ─────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final CartItemEntity item;
  final int number;
  final bool isAdmin;
  final bool isLast;
  const _ItemRow({
    required this.item,
    required this.number,
    required this.isAdmin,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###.00');
    final total = item.product.price * item.quantity;
    final cost = item.product.costPrice * item.quantity;
    final profit = total - cost;
    final profitPct = cost > 0 ? (profit / cost) * 100 : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: ViberantColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ViberantColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.quantity} × ₵${fmt.format(item.product.price)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ViberantColors.outline,
                      ),
                    ),
                    if (item.notes?.isNotEmpty == true)
                      Text(
                        'Note: ${item.notes}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: ViberantColors.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₵${fmt.format(total)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ViberantColors.primary,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Cost ₵${fmt.format(cost)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: ViberantColors.outline,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          profit >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 12,
                          color: profit >= 0
                              ? ViberantColors.success
                              : ViberantColors.error,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '₵${fmt.format(profit.abs())} (${profitPct.toStringAsFixed(0)}%)',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: profit >= 0
                                ? ViberantColors.success
                                : ViberantColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.3),
          ),
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }
}

// ─── Profit metric tile ───────────────────────────────────────────────────────
class _ProfitMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ProfitMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: ViberantColors.outline),
        ),
        const SizedBox(height: 4),
        Text(
          '₵${NumberFormat('#,###.00').format(value.abs())}',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

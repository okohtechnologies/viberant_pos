// lib/presentation/pages/orders/sales_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/viberant_card.dart';

class SaleDetailsPage extends StatelessWidget {
  final SaleEntity sale;

  const SaleDetailsPage({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final dateStr = DateFormat(
      'EEEE, d MMMM yyyy  ·  hh:mm a',
    ).format(sale.saleDate);

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

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Sale Details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy transaction ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sale.transactionId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction ID copied'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ──
          ViberantCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ViberantColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 26,
                    color: ViberantColors.success,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currency.format(sale.finalAmount),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                StatusChip(label: sale.status.name, status: chipStatus),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: sale.transactionId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Text(
                    sale.transactionId,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Transaction details ──
          _SectionLabel('Transaction Details'),
          const SizedBox(height: 8),
          ViberantCard(
            child: Column(
              children: [
                _DetailRow(
                  label: 'Cashier',
                  value: sale.cashierName,
                  icon: Icons.person_outline_rounded,
                ),
                _Divider(),
                _DetailRow(
                  label: 'Customer',
                  value: sale.customerName?.isNotEmpty == true
                      ? sale.customerName!
                      : 'Walk-in Customer',
                  icon: Icons.people_outline_rounded,
                ),
                _Divider(),
                _DetailRow(
                  label: 'Payment',
                  value: _paymentLabel(sale.paymentMethod),
                  icon: _paymentIcon(sale.paymentMethod),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Items ──
          _SectionLabel(
            '${sale.items.length} Item${sale.items.length == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 8),
          ViberantCard(
            child: Column(
              children: sale.items.map((item) {
                final isLast = item == sale.items.last;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ViberantRadius.md,
                            ),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child:
                                  item.product.imageUrl != null &&
                                      item.product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      item.product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _thumbPlaceholder(scheme),
                                    )
                                  : _thumbPlaceholder(scheme),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name + unit price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${currency.format(item.product.price)} × ${item.quantity}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currency.format(item.subtotal),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 72,
                        color: scheme.outlineVariant,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── Totals ──
          _SectionLabel('Summary'),
          const SizedBox(height: 8),
          ViberantCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TotalRow(
                  'Subtotal',
                  sale.totalAmount,
                  currency: currency,
                  scheme: scheme,
                ),
                const SizedBox(height: 8),
                _TotalRow(
                  'Tax (3%)',
                  sale.taxAmount,
                  currency: currency,
                  scheme: scheme,
                  isSecondary: true,
                ),
                if (sale.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  _TotalRow(
                    'Discount',
                    -sale.discountAmount,
                    currency: currency,
                    scheme: scheme,
                    isSecondary: true,
                    isDiscount: true,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      currency.format(sale.finalAmount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder(ColorScheme s) => Container(
    color: s.surfaceContainerHigh,
    child: Icon(
      Icons.inventory_2_outlined,
      size: 18,
      color: s.onSurfaceVariant.withValues(alpha: 0.4),
    ),
  );

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.momo:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  IconData _paymentIcon(PaymentMethod m) {
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 46,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final NumberFormat currency;
  final ColorScheme scheme;
  final bool isSecondary;
  final bool isDiscount;

  const _TotalRow(
    this.label,
    this.amount, {
    required this.currency,
    required this.scheme,
    this.isSecondary = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isSecondary ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
      Text(
        isDiscount
            ? '- ${currency.format(amount.abs())}'
            : currency.format(amount),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDiscount
              ? ViberantColors.success
              : isSecondary
              ? scheme.onSurfaceVariant
              : scheme.onSurface,
        ),
      ),
    ],
  );
}

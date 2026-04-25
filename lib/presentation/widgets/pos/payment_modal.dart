import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../providers/cart_provider.dart';

class PaymentModal extends ConsumerStatefulWidget {
  final double totalAmount;
  final VoidCallback onPaymentComplete;
  final String businessId;
  final String cashierId;
  final String cashierName;

  const PaymentModal({
    super.key,
    required this.totalAmount,
    required this.onPaymentComplete,
    required this.businessId,
    required this.cashierId,
    required this.cashierName,
  });

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  PaymentMethod? _selected;
  bool _processing = false;

  static const _methods = [
    (PaymentMethod.cash, 'Cash', Icons.money_rounded, ViberantColors.success),
    (
      PaymentMethod.momo,
      'Mobile Money',
      Icons.phone_android_rounded,
      ViberantColors.primary,
    ),
    (
      PaymentMethod.card,
      'Card',
      Icons.credit_card_rounded,
      ViberantColors.warning,
    ),
    (
      PaymentMethod.bankTransfer,
      'Bank Transfer',
      Icons.account_balance_rounded,
      ViberantColors.info,
    ),
    (
      PaymentMethod.credit,
      'Credit',
      Icons.receipt_long_rounded,
      ViberantColors.error,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###.00');

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ViberantColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Process Payment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₵${fmt.format(widget.totalAmount)}',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: ViberantColors.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Payment method grid (2 columns)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: _methods.map((m) {
                  final (method, name, icon, color) = m;
                  final isSelected = _selected == method;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = method),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.1)
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : cs.outlineVariant.withOpacity(0.4),
                          width: isSelected ? 2 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 22, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? color : cs.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _processing
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_processing || _selected == null)
                            ? null
                            : _confirmPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selected == null
                              ? ViberantColors.outline
                              : ViberantColors.primary,
                        ),
                        child: _processing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Confirm Payment',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPayment() async {
    if (_selected == null) return;

    // Confirm dialog
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        final (_, name, icon, color) = _methods.firstWhere(
          (m) => m.$1 == _selected,
        );
        return AlertDialog(
          title: Text(
            'Confirm Payment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₵${NumberFormat('#,###.00').format(widget.totalAmount)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ViberantColors.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;
    setState(() => _processing = true);

    try {
      final sale = await ref
          .read(cartProvider.notifier)
          .processPayment(
            businessId: widget.businessId,
            cashierId: widget.cashierId,
            cashierName: widget.cashierName,
            paymentMethod: _selected!,
            saleRepository: ref.read(saleRepositoryProvider),
          )
          .timeout(const Duration(seconds: 30));

      if (mounted) {
        Navigator.pop(context);
        _showSuccess(sale);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showSuccess(SaleEntity sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: ViberantColors.success,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Payment Successful',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ViberantColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '₵${NumberFormat('#,###.00').format(sale.finalAmount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ViberantColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TXN: ${sale.transactionId}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ViberantColors.outline,
                    ),
                  ),
                  Text(
                    '${sale.items.length} items · ${sale.cashierName}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ViberantColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentComplete();
            },
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ReceiptService.generateAndShareReceipt(sale, context);
            },
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Share Receipt'),
          ),
        ],
      ),
    );
  }

  void _showError(String error) {
    String msg = error;
    if (error.contains('Cart is empty'))
      msg = 'Cart is empty';
    else if (error.contains('Insufficient stock'))
      msg = 'Insufficient stock for one or more items';
    else if (error.contains('timed out'))
      msg = 'Payment timed out. Check your connection';
    else
      msg = error.replaceAll('Exception:', '').trim();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: ViberantColors.error,
            ),
            const SizedBox(width: 8),
            Text(
              'Payment Failed',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          msg,
          style: GoogleFonts.inter(color: ViberantColors.outline),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

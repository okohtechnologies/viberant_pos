// lib/presentation/widgets/pos/payment_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viberant_pos/presentation/providers/sale_repository_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../domain/states/auth_state.dart';

class PaymentModal extends ConsumerStatefulWidget {
  const PaymentModal({super.key});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  PaymentMethod _selected = PaymentMethod.cash;
  bool _isProcessing = false;
  final _customerCtrl = TextEditingController();

  static const _methods = [
    _PayMethod(PaymentMethod.cash, Icons.payments_rounded, 'Cash'),
    _PayMethod(PaymentMethod.momo, Icons.phone_android_rounded, 'MoMo'),
    _PayMethod(PaymentMethod.card, Icons.credit_card_rounded, 'Card'),
    _PayMethod(
      PaymentMethod.bankTransfer,
      Icons.account_balance_rounded,
      'Bank',
    ),
    _PayMethod(PaymentMethod.credit, Icons.handshake_outlined, 'Credit'),
  ];

  @override
  void dispose() {
    _customerCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    final cart = ref.read(cartProvider.notifier);
    final repo = ref.read(saleRepositoryProvider);

    setState(() => _isProcessing = true);
    try {
      final sale = await cart.processPayment(
        businessId: auth.user.businessId,
        cashierId: auth.user.id,
        cashierName: auth.user.displayName,
        paymentMethod: _selected,
        saleRepository: repo,
        customerName: _customerCtrl.text.trim().isNotEmpty
            ? _customerCtrl.text.trim()
            : null,
      );
      if (mounted) Navigator.pop(context, sale);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(cartSummaryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ViberantRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Payment',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'GHS ${summary.totalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Subtotal GHS ${summary.subtotal.toStringAsFixed(2)}  ·  Tax GHS ${summary.taxAmount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // Payment method grid
          Text(
            'Payment method',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: _methods
                .map(
                  (m) => _MethodTile(
                    method: m,
                    isSelected: _selected == m.method,
                    onTap: () => setState(() => _selected = m.method),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 20),

          // Customer name (optional)
          Text(
            'Customer name (optional)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customerCtrl,
            style: GoogleFonts.inter(fontSize: 14, color: scheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Walk-in customer',
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
            ),
          ),

          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ViberantRadius.card),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Confirm Payment',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayMethod {
  final PaymentMethod method;
  final IconData icon;
  final String label;
  const _PayMethod(this.method, this.icon, this.label);
}

class _MethodTile extends StatelessWidget {
  final _PayMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.1)
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          border: isSelected
              ? Border.all(color: scheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              method.icon,
              size: 22,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              method.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

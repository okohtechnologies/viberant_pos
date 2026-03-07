// lib/presentation/widgets/pos/cart_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/domain/entities/cart_item_entity.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart';
import 'package:viberant_pos/presentation/widgets/pos/payment_modal.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import 'cart_item_widget.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartSummary = ref.watch(cartSummaryProvider);

    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        border: Border(
          left: BorderSide(color: ViberantColors.grey.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          // Cart Header
          _CartHeader(totalItems: cartSummary.totalItems),

          // Cart Items
          Expanded(
            child: cart.isEmpty
                ? _EmptyCartState()
                : _CartItemsList(cart: cart),
          ),

          // Cart Summary & Actions
          _CartFooter(cartSummary: cartSummary),
        ],
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  final int totalItems;

  const _CartHeader({required this.totalItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        border: Border(
          bottom: BorderSide(color: ViberantColors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Current Sale",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ViberantColors.onSurface,
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ViberantColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_rounded,
                  size: 16,
                  color: ViberantColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalItems items',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ViberantColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemsList extends StatelessWidget {
  final List<CartItemEntity> cart;

  const _CartItemsList({required this.cart});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cart.length,
      itemBuilder: (context, index) {
        return CartItemWidget(
          cartItem: cart[index],
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: ViberantColors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Cart is Empty",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ViberantColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add products to start a sale",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: ViberantColors.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartFooter extends ConsumerWidget {
  final CartSummary cartSummary;

  const _CartFooter({required this.cartSummary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        border: Border(
          top: BorderSide(color: ViberantColors.grey.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          // Summary
          _SummaryRow(label: "Subtotal", value: cartSummary.subtotal),
          const SizedBox(height: 8),
          _SummaryRow(label: "Tax (3%)", value: cartSummary.taxAmount),
          const SizedBox(height: 12),
          Container(height: 1, color: ViberantColors.grey.withOpacity(0.1)),
          const SizedBox(height: 12),
          _SummaryRow(
            label: "Total",
            value: cartSummary.totalAmount,
            isTotal: true,
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: ViberantColors.error),
                  ),
                  child: Text(
                    "Clear",
                    style: GoogleFonts.inter(
                      color: ViberantColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: cartSummary.totalItems > 0
                      ? () => _processPayment(context, ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Process Payment",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context, WidgetRef ref) {
    final cartSummary = ref.read(cartSummaryProvider);
    final authState = ref.read(authProvider);

    if (authState is! AuthAuthenticated) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentModal(
        totalAmount: cartSummary.totalAmount,
        onPaymentComplete: () {
          ref.read(cartProvider.notifier).clearCart();
          Navigator.pop(context);
        },
        businessId: authState.user.businessId,
        cashierId: authState.user.id,
        cashierName: authState.user.displayName,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal ? ViberantColors.onSurface : ViberantColors.grey,
          ),
        ),
        Text(
          'GHS ${NumberFormat('#,###.00').format(value)}',
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? ViberantColors.primary : ViberantColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _PaymentModal extends StatelessWidget {
  final double totalAmount;
  final VoidCallback onPaymentComplete;

  const _PaymentModal({
    required this.totalAmount,
    required this.onPaymentComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Process Payment",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'GHS ${NumberFormat('#,###.00').format(totalAmount)}',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: ViberantColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Payment Methods
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _PaymentMethodCard(
                method: "Cash",
                icon: Icons.money_rounded,
                onTap: onPaymentComplete,
              ),
              _PaymentMethodCard(
                method: "Mobile Money",
                icon: Icons.phone_android_rounded,
                onTap: onPaymentComplete,
              ),
              _PaymentMethodCard(
                method: "Card",
                icon: Icons.credit_card_rounded,
                onTap: onPaymentComplete,
              ),
              _PaymentMethodCard(
                method: "Credit",
                icon: Icons.receipt_long_rounded,
                onTap: onPaymentComplete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String method;
  final IconData icon;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ViberantColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: ViberantColors.primary),
              const SizedBox(height: 8),
              Text(
                method,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

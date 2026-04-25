import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/cart_item_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/widgets.dart';
import 'payment_modal.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_rounded,
                      color: ViberantColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Sale',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                if (summary.totalItems > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ViberantColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${summary.totalItems} items',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ViberantColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Items ────────────────────────────────────────────────────────────
          Expanded(
            child: cart.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Cart is Empty',
                    description: 'Tap a product to add it to this sale',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.length,
                    itemBuilder: (_, i) => _CartRow(item: cart[i])
                        .animate()
                        .fadeIn(delay: (i * 60).ms)
                        .slideX(begin: 0.05, end: 0),
                  ),
          ),

          // ── Footer ───────────────────────────────────────────────────────────
          if (cart.isNotEmpty) _CartFooter(summary: summary),
        ],
      ),
    );
  }
}

// ─── Cart item row ────────────────────────────────────────────────────────────
class _CartRow extends ConsumerWidget {
  final CartItemEntity item;
  const _CartRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ViberantColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: ViberantColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₵${NumberFormat('#,###.00').format(item.product.price)} each',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ViberantColors.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: subtotal + qty controls + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₵${NumberFormat('#,###.00').format(item.subtotal)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ViberantColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Qty controls
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _QtyBtn(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            if (item.quantity > 1) {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(
                                    item.product.id,
                                    item.quantity - 1,
                                  );
                            } else {
                              ref
                                  .read(cartProvider.notifier)
                                  .removeProduct(item.product.id);
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${item.quantity}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ViberantColors.primary,
                            ),
                          ),
                        ),
                        _QtyBtn(
                          icon: Icons.add_rounded,
                          onTap: () {
                            if (item.quantity < item.product.stock) {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(
                                    item.product.id,
                                    item.quantity + 1,
                                  );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Only ${item.product.stock} in stock',
                                  ),
                                  backgroundColor: ViberantColors.warning,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Delete
                  GestureDetector(
                    onTap: () => ref
                        .read(cartProvider.notifier)
                        .removeProduct(item.product.id),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: ViberantColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 15,
                        color: ViberantColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 28,
      height: 28,
      child: Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

// ─── Cart footer ──────────────────────────────────────────────────────────────
class _CartFooter extends ConsumerWidget {
  final CartSummary summary;
  const _CartFooter({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###.00');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          // Summary rows
          _SummaryRow('Subtotal', summary.subtotal, false, cs),
          const SizedBox(height: 6),
          _SummaryRow('Tax (3%)', summary.taxAmount, false, cs),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: cs.outlineVariant.withOpacity(0.4),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '₵${fmt.format(summary.totalAmount)}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ViberantColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              // Clear
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ViberantColors.error,
                    side: BorderSide(
                      color: ViberantColors.error.withOpacity(0.4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(width: 10),

              // Charge
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _openPayment(context, ref, summary),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Charge ₵${fmt.format(summary.totalAmount)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPayment(BuildContext context, WidgetRef ref, CartSummary summary) {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentModal(
        totalAmount: summary.totalAmount,
        businessId: auth.user.businessId,
        cashierId: auth.user.id,
        cashierName: auth.user.displayName,
        onPaymentComplete: () {
          ref.read(cartProvider.notifier).clearCart();
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final ColorScheme cs;
  const _SummaryRow(this.label, this.value, this.isTotal, this.cs);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 13, color: ViberantColors.outline),
      ),
      Text(
        '₵${NumberFormat('#,###.00').format(value)}',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      ),
    ],
  );
}

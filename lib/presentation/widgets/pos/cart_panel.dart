// lib/presentation/widgets/pos/cart_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import 'cart_item_widget.dart';
import 'payment_modal.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../widgets/common/empty_state.dart';

class CartPanel extends ConsumerWidget {
  final void Function(SaleEntity sale)? onSaleComplete;

  const CartPanel({super.key, this.onSaleComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);
    final notifier = ref.read(cartProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cart',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                if (cart.isNotEmpty)
                  TextButton.icon(
                    onPressed: notifier.clearCart,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items list
          Expanded(
            child: cart.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Cart is empty',
                    description: 'Tap a product to add it.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = cart[i];
                      return CartItemWidget(
                        item: item,
                        onIncrement: () => notifier.updateQuantity(
                          item.product.id,
                          item.quantity + 1,
                        ),
                        onDecrement: () => notifier.updateQuantity(
                          item.product.id,
                          item.quantity - 1,
                        ),
                        onRemove: () => notifier.removeProduct(item.product.id),
                      );
                    },
                  ),
          ),

          // Footer
          if (cart.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow(
                    'Subtotal',
                    'GHS ${summary.subtotal.toStringAsFixed(2)}',
                    scheme: scheme,
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(
                    'Tax (3%)',
                    'GHS ${summary.taxAmount.toStringAsFixed(2)}',
                    scheme: scheme,
                    isSecondary: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _SummaryRow(
                    'Total',
                    'GHS ${summary.totalAmount.toStringAsFixed(2)}',
                    scheme: scheme,
                    isBold: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final sale = await showModalBottomSheet<SaleEntity>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const PaymentModal(),
                        );
                        if (sale != null) onSaleComplete?.call(sale);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ViberantRadius.card,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Charge GHS ${summary.totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme scheme;
  final bool isBold;
  final bool isSecondary;

  const _SummaryRow(
    this.label,
    this.value, {
    required this.scheme,
    this.isBold = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isSecondary ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? scheme.primary : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

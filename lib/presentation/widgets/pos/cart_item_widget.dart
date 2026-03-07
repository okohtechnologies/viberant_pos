// lib/presentation/widgets/pos/cart_item_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/cart_item_entity.dart';
import '../../providers/cart_provider.dart';

class CartItemWidget extends ConsumerWidget {
  final CartItemEntity cartItem;

  const CartItemWidget({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Item Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: ViberantColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: ViberantColors.primary,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartItem.product.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ViberantColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'GHS ${NumberFormat('#,###.00').format(cartItem.product.price)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ViberantColors.primary,
                        ),
                      ),

                      if (cartItem.notes != null &&
                          cartItem.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          cartItem.notes!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: ViberantColors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Quantity Controls
                _QuantityControls(cartItem: cartItem),
              ],
            ),
          ),

          // Subtotal & Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ViberantColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal: GHS ${NumberFormat('#,###.00').format(cartItem.subtotal)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ViberantColors.onSurface,
                  ),
                ),

                Row(
                  children: [
                    // Edit Notes Button
                    _ActionButton(
                      icon: Icons.edit_note_rounded,
                      color: ViberantColors.grey,
                      onTap: () => _showNotesDialog(context, ref, cartItem),
                    ),

                    const SizedBox(width: 8),

                    // Remove Button
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: ViberantColors.error,
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .removeProduct(cartItem.product.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog(
    BuildContext context,
    WidgetRef ref,
    CartItemEntity cartItem,
  ) {
    final notesController = TextEditingController(text: cartItem.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Add Notes",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Add special instructions...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: ViberantColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (notesController.text != cartItem.notes) {
                // Update item with new notes
                final updatedItem = cartItem.copyWith(
                  notes: notesController.text,
                );
                // We need to remove and re-add to update notes
                ref
                    .read(cartProvider.notifier)
                    .removeProduct(cartItem.product.id);
                ref
                    .read(cartProvider.notifier)
                    .addProduct(
                      updatedItem.product,
                      quantity: updatedItem.quantity,
                      notes: updatedItem.notes,
                    );
              }
              Navigator.pop(context);
            },
            child: Text(
              "Save",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControls extends ConsumerWidget {
  final CartItemEntity cartItem;

  const _QuantityControls({required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Decrease Button
          _QuantityButton(
            icon: Icons.remove_rounded,
            onTap: () {
              if (cartItem.quantity > 1) {
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(cartItem.product.id, cartItem.quantity - 1);
              } else {
                ref
                    .read(cartProvider.notifier)
                    .removeProduct(cartItem.product.id);
              }
            },
          ),

          // Quantity Display
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              cartItem.quantity.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ViberantColors.primary,
              ),
            ),
          ),

          // Increase Button
          _QuantityButton(
            icon: Icons.add_rounded,
            onTap: () {
              if (cartItem.quantity < cartItem.product.stock) {
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(cartItem.product.id, cartItem.quantity + 1);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Only ${cartItem.product.stock} items in stock',
                    ),
                    backgroundColor: ViberantColors.warning,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: ViberantColors.primary),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

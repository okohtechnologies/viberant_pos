// lib/presentation/widgets/pos/cart_item_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/cart_item_entity.dart';

class CartItemWidget extends StatelessWidget {
  final CartItemEntity item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(ViberantRadius.md),
            child: SizedBox(
              width: 48,
              height: 48,
              child:
                  item.product.imageUrl != null &&
                      item.product.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumb(scheme),
                    )
                  : _thumb(scheme),
            ),
          ),
          const SizedBox(width: 12),

          // Name + subtotal
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
                const SizedBox(height: 3),
                Text(
                  'GHS ${item.subtotal.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyButton(
                icon: item.quantity == 1
                    ? Icons.delete_outline_rounded
                    : Icons.remove_rounded,
                onTap: item.quantity == 1 ? onRemove : onDecrement,
                color: item.quantity == 1
                    ? scheme.error
                    : scheme.onSurfaceVariant,
                bg: item.quantity == 1
                    ? scheme.errorContainer.withValues(alpha: 0.4)
                    : scheme.surfaceContainerHigh,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
                color: scheme.primary,
                bg: scheme.primary.withValues(alpha: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumb(ColorScheme s) => Container(
    color: s.surfaceContainerHigh,
    child: Icon(
      Icons.inventory_2_outlined,
      size: 20,
      color: s.onSurfaceVariant.withValues(alpha: 0.4),
    ),
  );
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color bg;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: color),
    ),
  );
}

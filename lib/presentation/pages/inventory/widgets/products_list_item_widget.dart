// lib/presentation/pages/inventory/widgets/products_list_item_widget.dart
// Extended product row with inline quantity stepper.
// Used in contexts where you want add-to-cart behaviour
// directly from a list (e.g. a staff product browser sheet).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/common/status_chip.dart';

class ProductsListItemWidget extends ConsumerWidget {
  final ProductEntity product;

  const ProductsListItemWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    final cartItem = cart.where((i) => i.product.id == product.id).firstOrNull;
    final qtyInCart = cartItem?.quantity ?? 0;

    final outOfStock = product.stock <= 0;
    final lowStock = product.stock > 0 && product.stock <= product.minStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ViberantRadius.card),
        boxShadow: ViberantShadows.level1,
        border: qtyInCart > 0
            ? Border.all(color: scheme.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(ViberantRadius.md),
              child: SizedBox(
                width: 52,
                height: 52,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumb(scheme),
                      )
                    : _thumb(scheme),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'GHS ${product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (outOfStock)
                        StatusChip.error(label: 'Out')
                      else if (lowStock)
                        StatusChip.warning(label: 'Low')
                      else
                        Text(
                          '${product.stock} in stock',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Qty controls
            if (outOfStock)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(ViberantRadius.full),
                ),
                child: Text(
                  'Out of stock',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else if (qtyInCart == 0)
              GestureDetector(
                onTap: () => notifier.addProduct(product),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyBtn(
                    icon: qtyInCart == 1
                        ? Icons.delete_outline_rounded
                        : Icons.remove_rounded,
                    color: qtyInCart == 1
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                    bg: qtyInCart == 1
                        ? scheme.errorContainer.withValues(alpha: 0.4)
                        : scheme.surfaceContainerHigh,
                    onTap: () =>
                        notifier.updateQuantity(product.id, qtyInCart - 1),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$qtyInCart',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  _QtyBtn(
                    icon: Icons.add_rounded,
                    color: scheme.primary,
                    bg: scheme.primary.withValues(alpha: 0.1),
                    onTap: () => notifier.addProduct(product),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(ColorScheme s) => Container(
    color: s.surfaceContainerHigh,
    child: Icon(
      Icons.inventory_2_outlined,
      size: 22,
      color: s.onSurfaceVariant.withValues(alpha: 0.4),
    ),
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QtyBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
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

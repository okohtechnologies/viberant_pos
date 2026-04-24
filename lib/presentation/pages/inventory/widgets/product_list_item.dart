// lib/presentation/pages/inventory/widgets/product_list_item.dart
// Compact list row used in contexts that need a simpler product
// representation than the full _ProductRow in inventory_page.dart.
// e.g. search results, selection sheets.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../widgets/common/status_chip.dart';

class ProductListItem extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProductListItem({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outOfStock = product.stock <= 0;
    final lowStock = product.stock > 0 && product.stock <= product.minStock;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ViberantRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(ViberantRadius.md),
              child: SizedBox(
                width: 44,
                height: 44,
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

            // Name + meta
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        product.category,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (outOfStock) ...[
                        const SizedBox(width: 8),
                        StatusChip.error(label: 'Out'),
                      ] else if (lowStock) ...[
                        const SizedBox(width: 8),
                        StatusChip.warning(label: 'Low'),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Price + optional trailing
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'GHS ${product.price.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 4),
                  trailing!,
                ] else
                  Text(
                    '${product.stock} left',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: outOfStock
                          ? ViberantColors.error
                          : lowStock
                          ? ViberantColors.warning
                          : scheme.onSurfaceVariant,
                    ),
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
      size: 20,
      color: s.onSurfaceVariant.withValues(alpha: 0.4),
    ),
  );
}

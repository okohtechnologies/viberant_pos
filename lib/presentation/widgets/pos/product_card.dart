// lib/presentation/widgets/pos/product_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/product_entity.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  final bool isCompact;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outOfStock = product.stock <= 0;
    final lowStock = product.stock > 0 && product.stock <= product.minStock;

    return GestureDetector(
      onTap: outOfStock ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: outOfStock ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(ViberantRadius.card),
            boxShadow: ViberantShadows.level1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Expanded(
                flex: isCompact ? 3 : 4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ViberantRadius.card),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(scheme),
                            )
                          : _placeholder(scheme),
                      // Stock badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _stockBadge(outOfStock, lowStock),
                      ),
                    ],
                  ),
                ),
              ),

              // Info area
              Expanded(
                flex: isCompact ? 2 : 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: isCompact ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GHS ${product.price.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isCompact ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          Text(
                            'x${product.stock}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: lowStock
                                  ? ViberantColors.warning
                                  : scheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) => Container(
    color: scheme.surfaceContainerHigh,
    child: Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 28,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    ),
  );

  Widget _stockBadge(bool outOfStock, bool lowStock) {
    if (!outOfStock && !lowStock) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: outOfStock
            ? ViberantColors.error.withValues(alpha: 0.9)
            : ViberantColors.warning.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(ViberantRadius.full),
      ),
      child: Text(
        outOfStock ? 'Out' : 'Low',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

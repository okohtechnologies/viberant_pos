// lib/presentation/widgets/pos/product_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/domain/entities/cart_item_entity.dart';
import 'package:collection/collection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/cart_provider.dart';

class ProductCard extends ConsumerWidget {
  final ProductEntity product;

  const ProductCard({super.key, required this.product, required bool isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartItem = cart
        .where((item) => item.product.id == product.id)
        .firstOrNull;
    final quantityInCart = cartItem?.quantity ?? 0;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _addToCart(ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Placeholder
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ViberantColors.primary.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: ViberantColors.primary,
                      size: 40,
                    ),
                  ),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          product.description,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: ViberantColors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GHS ${NumberFormat('#,###.00').format(product.price)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ViberantColors.primary,
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: product.stock < product.minStock
                                    ? ViberantColors.error.withValues(alpha: 0.1)
                                    : ViberantColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product.stock} in stock',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: product.stock < product.minStock
                                      ? ViberantColors.error
                                      : ViberantColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Add to Cart Button
              if (quantityInCart == 0)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ViberantColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ).animate().scale(duration: 300.ms).fadeIn(),

              // Quantity Indicator
              if (quantityInCart > 0)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ViberantColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quantityInCart.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(WidgetRef ref) {
    if (product.stock > 0) {
      ref.read(cartProvider.notifier).addProduct(product);

      // Haptic feedback
      // HapticFeedback.lightImpact();
    }
  }
}

extension on List<CartItemEntity> {}

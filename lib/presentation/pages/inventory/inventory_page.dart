// lib/presentation/pages/inventory/inventory_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/viberant_card.dart';
import 'widgets/add_product_dialog.dart';
import 'widgets/edit_product_dialog.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final outOfStockAsync = ref.watch(outOfStockProductsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddProductDialog(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Product',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          // Stats chips row
          _buildStatsRow(productsAsync, outOfStockAsync, scheme),

          // Search + category filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search inventory…',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),

          // Category chips
          categoriesAsync.when(
            loading: () => const SizedBox(height: 8),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ['All', ...cats].length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = ['All', ...cats][i];
                    final active = _category == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(
                            ViberantRadius.full,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Product list
          Expanded(
            child: productsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(count: 8),
              ),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Failed to load inventory',
                description: e.toString(),
              ),
              data: (products) {
                final filtered = products.where((p) {
                  final matchQ =
                      _query.isEmpty ||
                      p.name.toLowerCase().contains(_query.toLowerCase());
                  final matchC = _category == 'All' || p.category == _category;
                  return matchQ && matchC;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products',
                    description:
                        'Add your first product using the button below.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ProductRow(product: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<ProductEntity>> productsAsync,
    AsyncValue<List<ProductEntity>> outOfStockAsync,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          productsAsync.when(
            loading: () => const LoadingShimmer(width: 100, height: 28),
            error: (_, __) => const SizedBox.shrink(),
            data: (products) => _StatChip(
              label: '${products.length} Products',
              color: ViberantColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          outOfStockAsync.when(
            loading: () => const LoadingShimmer(width: 80, height: 28),
            error: (_, __) => const SizedBox.shrink(),
            data: (oos) => oos.isNotEmpty
                ? _StatChip(
                    label: '${oos.length} Out of Stock',
                    color: ViberantColors.error,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(ViberantRadius.full),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

class _ProductRow extends ConsumerWidget {
  final ProductEntity product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final outOfStock = product.stock <= 0;
    final lowStock = product.stock > 0 && product.stock <= product.minStock;
    final stockPct =
        (product.minStock > 0 ? product.stock / (product.minStock * 3) : 1.0)
            .clamp(0.0, 1.0);

    return ViberantCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Image
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (outOfStock)
                      StatusChip.error(label: 'Out')
                    else if (lowStock)
                      StatusChip.warning(label: 'Low'),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  product.category +
                      (product.sku != null ? '  ·  ${product.sku}' : ''),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),

                // Stock bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: stockPct,
                          minHeight: 4,
                          backgroundColor: scheme.surfaceContainerHigh,
                          color: outOfStock
                              ? ViberantColors.error
                              : lowStock
                              ? ViberantColors.warning
                              : ViberantColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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

          const SizedBox(width: 12),

          // Price + edit
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
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => EditProductDialog(product: product),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(ViberantRadius.sm),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
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
      size: 22,
      color: s.onSurfaceVariant.withValues(alpha: 0.4),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_filter_provider.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/pos/category_filter.dart';
import '../inventory/widgets/add_product_dialog.dart';

class ProductsPage extends ConsumerStatefulWidget {
  final String businessId;
  const ProductsPage({super.key, required this.businessId});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCat = 'All';
  List<String> _cats = ['All'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    final productsAsync = ref.watch(
      filteredProductsProvider(
        ProductsFilterParams(
          businessId: widget.businessId,
          searchQuery: _searchQuery,
          category: _selectedCat == 'All' ? null : _selectedCat,
        ),
      ),
    );

    // Derive categories from unfiltered list
    final allAsync = ref.watch(
      filteredProductsProvider(
        ProductsFilterParams(businessId: widget.businessId),
      ),
    );
    allAsync.whenData((all) {
      final cats = [
        'All',
        ...{...all.map((p) => p.category)},
      ];
      if (cats.length != _cats.length) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _cats = cats),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // App bar + search
          _AppBar(
            ctrl: _searchCtrl,
            onSearch: (v) => setState(() => _searchQuery = v),
          ),

          // Category filter
          CategoryFilter(
            selectedCategory: _selectedCat,
            onCategorySelected: (c) => setState(() => _selectedCat = c),
            categories: _cats,
            isMobile: true,
          ),

          // List
          Expanded(
            child: productsAsync.when(
              loading: () => const ShimmerList(count: 6, itemHeight: 76),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load products',
                description: e.toString(),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: _searchQuery.isEmpty ? 'No products' : 'No results',
                    description: _searchQuery.isEmpty
                        ? 'Products will appear here'
                        : 'Try different search terms',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _ProductBrowseRow(
                    product: products[i],
                  ).animate().fadeIn(delay: (i * 35).ms).slideY(begin: 0.05),
                );
              },
            ),
          ),
        ],
      ),

      // FAB only for admins
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                if (authState is! AuthAuthenticated) return;
                showDialog(
                  context: context,
                  builder: (_) => AddProductDialog(
                    businessId: widget.businessId,
                    onProductAdded: () =>
                        ref.invalidate(filteredProductsProvider),
                    isMobile: true,
                  ),
                );
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

// ─── App bar with search ──────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onSearch;
  const _AppBar({required this.ctrl, required this.onSearch});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      bottom: 12,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      boxShadow: [
        BoxShadow(
          color: ViberantColors.primary.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Text(
              'Products',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl,
          onChanged: onSearch,
          decoration: const InputDecoration(
            hintText: 'Search products…',
            prefixIcon: Icon(Icons.search_rounded),
            constraints: BoxConstraints(maxHeight: 44),
          ),
        ),
      ],
    ),
  );
}

// ─── Product browse row ───────────────────────────────────────────────────────
class _ProductBrowseRow extends StatelessWidget {
  final ProductEntity product;
  const _ProductBrowseRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: ViberantColors.primary.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: ViberantColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              image: product.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(product.imageUrl!),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    )
                  : null,
            ),
            child: product.imageUrl == null
                ? const Icon(
                    Icons.shopping_bag_outlined,
                    color: ViberantColors.primary,
                    size: 22,
                  )
                : null,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _CatChip(product.category),
                    if (product.sku != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        product.sku!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: ViberantColors.outline,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                StatusChip.fromStockStatus(product.stockStatus),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Price + stock
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₵${NumberFormat('#,###.00').format(product.price)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ViberantColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${product.stock} in stock',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: product.stockStatusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  const _CatChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: ViberantColors.outline,
      ),
    ),
  );
}

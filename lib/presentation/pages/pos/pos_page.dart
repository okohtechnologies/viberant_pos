import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/products_provider.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/pos/cart_panel.dart';
import '../../widgets/pos/category_filter.dart';

class PosPage extends HookConsumerWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl = useTextEditingController();
    final searchQuery = useState('');
    final selectedCategory = useState('All');
    final productsAsync = ref.watch(productsProvider);
    final authState = ref.watch(authProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < Breakpoints.mobile;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.login_rounded,
          title: 'Please Sign In',
          description: 'You need to be signed in to use the POS',
        ),
      );
    }

    return productsAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _PosHeader(ctrl: searchCtrl, onSearch: (_) {}, isMobile: isMobile),
            const Expanded(child: ShimmerGrid(count: 6, crossAxisCount: 2)),
          ],
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load products',
          description: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(productsProvider),
        ),
      ),
      data: (products) {
        final filtered = products.where((p) {
          final q = searchQuery.value.toLowerCase();
          final matchQ =
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              (p.sku?.toLowerCase().contains(q) ?? false);
          final matchCat =
              selectedCategory.value == 'All' ||
              p.category == selectedCategory.value;
          return matchQ && matchCat && p.stock > 0;
        }).toList();

        final categories = [
          'All',
          ...{...products.map((p) => p.category)},
        ];

        if (isMobile) {
          return _MobileLayout(
            searchCtrl: searchCtrl,
            searchQuery: searchQuery,
            selectedCategory: selectedCategory,
            categories: categories,
            products: filtered,
          );
        }
        return _DesktopLayout(
          searchCtrl: searchCtrl,
          searchQuery: searchQuery,
          selectedCategory: selectedCategory,
          categories: categories,
          products: filtered,
        );
      },
    );
  }
}

// ─── Desktop layout (63/37 split) ────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueNotifier<String> searchQuery;
  final ValueNotifier<String> selectedCategory;
  final List<String> categories;
  final List<ProductEntity> products;

  const _DesktopLayout({
    required this.searchCtrl,
    required this.searchQuery,
    required this.selectedCategory,
    required this.categories,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 63,
          child: Column(
            children: [
              _PosHeader(
                ctrl: searchCtrl,
                onSearch: (v) => searchQuery.value = v,
                isMobile: false,
              ),
              CategoryFilter(
                selectedCategory: selectedCategory.value,
                onCategorySelected: (c) => selectedCategory.value = c,
                categories: categories,
                isMobile: false,
              ),
              Expanded(
                child: products.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: searchQuery.value.isEmpty
                            ? 'No products available'
                            : 'No results',
                        description: searchQuery.value.isEmpty
                            ? 'Add products in Inventory'
                            : 'Try a different search',
                      )
                    : _ProductGrid(products: products, isMobile: false),
              ),
            ],
          ),
        ),
        Container(
          width: 0.5,
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
        ),
        const Expanded(flex: 37, child: CartPanel()),
      ],
    );
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueNotifier<String> searchQuery;
  final ValueNotifier<String> selectedCategory;
  final List<String> categories;
  final List<ProductEntity> products;

  const _MobileLayout({
    required this.searchCtrl,
    required this.searchQuery,
    required this.selectedCategory,
    required this.categories,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _PosHeader(
              ctrl: searchCtrl,
              onSearch: (v) => searchQuery.value = v,
              isMobile: true,
            ),
            CategoryFilter(
              selectedCategory: selectedCategory.value,
              onCategorySelected: (c) => selectedCategory.value = c,
              categories: categories,
              isMobile: true,
            ),
            Expanded(
              child: products.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: searchQuery.value.isEmpty
                          ? 'No products'
                          : 'No results',
                      description: searchQuery.value.isEmpty
                          ? 'Add products in Inventory'
                          : 'Try different terms',
                    )
                  : _ProductGrid(products: products, isMobile: true),
            ),
            const _MobileCartBar(),
          ],
        ),
      ),
    );
  }
}

// ─── Product grid ─────────────────────────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  final List<ProductEntity> products;
  final bool isMobile;
  const _ProductGrid({required this.products, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cols = isMobile ? 2 : 3;
    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: isMobile ? 10 : 12,
        mainAxisSpacing: isMobile ? 10 : 12,
        childAspectRatio: isMobile ? 0.72 : 0.78,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(
        product: products[i],
      ).animate().fadeIn(delay: (i * 30).ms).slideY(begin: 0.06, end: 0),
    );
  }
}

// ─── Product card ─────────────────────────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final ProductEntity product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final qty =
        cart.firstWhereOrNull((i) => i.product.id == product.id)?.quantity ?? 0;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (product.stock > 0) {
            ref.read(cartProvider.notifier).addProduct(product);
          }
        },
        splashColor: ViberantColors.primary.withOpacity(0.08),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: qty > 0
                  ? ViberantColors.primary.withOpacity(0.3)
                  : cs.outlineVariant.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: ViberantColors.primary.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ViberantColors.primary.withOpacity(0.07),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _PlaceholderIcon(),
                          ),
                        )
                      : _PlaceholderIcon(),
                ),
              ),

              // Info
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₵${NumberFormat('#,###.00').format(product.price)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ViberantColors.primary,
                            ),
                          ),

                          // Stock badge / qty indicator
                          if (qty == 0)
                            _StockBadge(product: product)
                          else
                            _QtyBadge(qty: qty),
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
}

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Icon(
      Icons.shopping_bag_outlined,
      color: ViberantColors.primary.withOpacity(0.4),
      size: 36,
    ),
  );
}

class _StockBadge extends StatelessWidget {
  final ProductEntity product;
  const _StockBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    final color = product.isLowStock
        ? ViberantColors.warning
        : ViberantColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${product.stock}',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _QtyBadge extends StatelessWidget {
  final int qty;
  const _QtyBadge({required this.qty});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: ViberantColors.primary,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '$qty',
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  ).animate().scale(duration: 200.ms, curve: Curves.elasticOut);
}

// ─── POS Header ───────────────────────────────────────────────────────────────
class _PosHeader extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onSearch;
  final bool isMobile;
  const _PosHeader({
    required this.ctrl,
    required this.onSearch,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search products, SKU…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: ViberantColors.outline,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          ctrl.clear();
                          onSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                constraints: const BoxConstraints(maxHeight: 44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile cart bar (bottom) ─────────────────────────────────────────────────
class _MobileCartBar extends ConsumerWidget {
  const _MobileCartBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // Cart info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${summary.totalItems} items in cart',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ViberantColors.outline,
                  ),
                ),
                Text(
                  '₵${NumberFormat('#,###.00').format(summary.totalAmount)}',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ViberantColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // View Cart button
          ElevatedButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.82,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: const CartPanel(),
                ),
              ),
            ),
            icon: const Icon(Icons.shopping_cart_rounded, size: 18),
            label: const Text('View Cart'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

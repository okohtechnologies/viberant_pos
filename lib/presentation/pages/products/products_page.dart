// lib/presentation/pages/products/products_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_filter_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/pos/category_filter.dart';
import '../../widgets/pos/product_card.dart';
import '../../providers/cart_provider.dart';
import '../../providers/inventory_provider.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final categoriesAsync = ref.watch(categoriesProvider);
    final filteredAsync = ref.watch(
      filteredProductsProvider(
        FilterParams(
          businessId: authState.user.businessId,
          searchQuery: _query,
          category: _category == 'All' ? null : _category,
        ),
      ),
    );
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category filter
          categoriesAsync.when(
            loading: () => const SizedBox(height: 36),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => CategoryFilter(
              categories: cats,
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
          ),

          const SizedBox(height: 8),

          // Grid
          Expanded(
            child: filteredAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(count: 8),
              ),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Failed to load products',
                description: e.toString(),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: _query.isNotEmpty ? 'No results' : 'No products',
                    description: _query.isNotEmpty
                        ? 'Try a different search term.'
                        : 'No products available.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns(width),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) =>
                      ProductCard(
                        product: products[i],
                        onTap: () {
                          ref
                              .read(cartProvider.notifier)
                              .addProduct(products[i]);
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${products[i].name} added to cart',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                        },
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: i * 25),
                        duration: 250.ms,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

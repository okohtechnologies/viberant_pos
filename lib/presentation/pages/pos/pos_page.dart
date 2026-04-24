// lib/presentation/pages/pos/pos_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../providers/cart_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/products_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/pos/cart_panel.dart';
import '../../widgets/pos/category_filter.dart';
import '../../widgets/pos/payment_modal.dart';
import '../../widgets/pos/product_card.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductEntity> _filter(List<ProductEntity> all) {
    return all.where((p) {
      if (p.stock <= 0) return false;
      final matchQ =
          _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase());
      final matchC = _category == 'All' || p.category == _category;
      return matchQ && matchC;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cartSummary = ref.watch(cartSummaryProvider);
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= Breakpoints.desktop;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: isDesktop
          ? _buildDesktopLayout(productsAsync, categoriesAsync, scheme)
          : _buildMobileLayout(
              productsAsync,
              categoriesAsync,
              cartSummary,
              scheme,
            ),
    );
  }

  Widget _buildDesktopLayout(
    AsyncValue<List<ProductEntity>> productsAsync,
    AsyncValue<List<String>> categoriesAsync,
    ColorScheme scheme,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 63,
          child: _buildProductArea(productsAsync, categoriesAsync, scheme),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.37,
          child: CartPanel(onSaleComplete: _onSaleComplete),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    AsyncValue<List<ProductEntity>> productsAsync,
    AsyncValue<List<String>> categoriesAsync,
    CartSummary cartSummary,
    ColorScheme scheme,
  ) {
    return Stack(
      children: [
        _buildProductArea(productsAsync, categoriesAsync, scheme),
        if (cartSummary.totalItems > 0)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _CartFAB(
              summary: cartSummary,
              onTap: () async {
                final sale = await showModalBottomSheet<SaleEntity>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const PaymentModal(),
                );
                if (sale != null) _onSaleComplete(sale);
              },
              onViewCart: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  maxChildSize: 0.92,
                  minChildSize: 0.4,
                  expand: false,
                  builder: (_, ctrl) =>
                      CartPanel(onSaleComplete: _onSaleComplete),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductArea(
    AsyncValue<List<ProductEntity>> productsAsync,
    AsyncValue<List<String>> categoriesAsync,
    ColorScheme scheme,
  ) {
    return Column(
      children: [
        // Search bar
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

        // Category chips
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

        // Product grid
        Expanded(
          child: productsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 8),
            ),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Failed to load products',
              description: e.toString(),
            ),
            data: (all) {
              final products = _filter(all);
              if (products.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: _query.isNotEmpty ? 'No results' : 'No products',
                  description: _query.isNotEmpty
                      ? 'Try a different search term.'
                      : 'Add products in the Inventory tab.',
                );
              }
              final width = MediaQuery.of(context).size.width;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                        ref.read(cartProvider.notifier).addProduct(products[i]);
                        _showAddedFeedback(products[i].name);
                      },
                    ).animate().fadeIn(
                      delay: Duration(milliseconds: i * 30),
                      duration: 250.ms,
                    ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddedFeedback(String name) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('$name added to cart'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  void _onSaleComplete(SaleEntity sale) {
    showDialog(
      context: context,
      builder: (_) => _SuccessDialog(sale: sale),
    );
  }
}

class _CartFAB extends StatelessWidget {
  final CartSummary summary;
  final VoidCallback onTap;
  final VoidCallback onViewCart;

  const _CartFAB({
    required this.summary,
    required this.onTap,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewCart,
        borderRadius: BorderRadius.circular(ViberantRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(ViberantRadius.card),
            boxShadow: ViberantShadows.level4Modal,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${summary.totalItems}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'View Cart',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'GHS ${summary.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(ViberantRadius.full),
                  ),
                  child: Text(
                    'Pay',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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

class _SuccessDialog extends StatelessWidget {
  final SaleEntity sale;
  const _SuccessDialog({required this.sale});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ViberantRadius.lg),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ViberantColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 32,
              color: ViberantColors.success,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'Payment Successful!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GHS ${sale.finalAmount.toStringAsFixed(2)}  ·  ${sale.items.length} item${sale.items.length == 1 ? '' : 's'}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sale.transactionId,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

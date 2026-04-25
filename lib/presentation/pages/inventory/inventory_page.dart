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
import '../../providers/inventory_provider.dart';
import '../../widgets/common/widgets.dart';
import 'widgets/add_product_dialog.dart';
import 'widgets/edit_product_dialog.dart';

class InventoryPage extends HookConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl = useTextEditingController();
    final searchQuery = useState('');
    final selectedCat = ref.watch(selectedCategoryProvider);
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final authState = ref.watch(authProvider);
    final isMobile = Breakpoints.isMobile(context);

    final filtered =
        productsAsync.asData?.value.where((p) {
          final q = searchQuery.value.toLowerCase();
          final hit =
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              (p.sku?.toLowerCase().contains(q) ?? false);
          final cat = selectedCat == 'All' || p.category == selectedCat;
          return hit && cat;
        }).toList() ??
        [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            _InventoryHeader(productsAsync: productsAsync),

            // ── Stat chips ──────────────────────────────────────────────────
            if (productsAsync.asData?.value != null)
              Builder(
                builder: (_) {
                  final products = productsAsync.asData!.value;
                  final low = products.where((p) => p.isLowStock).length;
                  final out = products.where((p) => p.isOutOfStock).length;
                  return _StatChips(total: products.length, low: low, out: out);
                },
              ),

            // ── Search + filter ─────────────────────────────────────────────
            _SearchFilter(
              ctrl: searchCtrl,
              onSearch: (v) => searchQuery.value = v,
              selectedCat: selectedCat,
              categories: categoriesAsync.value ?? [],
              onCatChanged: (c) =>
                  ref.read(selectedCategoryProvider.notifier).state = c,
            ),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: productsAsync.when(
                loading: () => const ShimmerList(count: 6, itemHeight: 80),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load products',
                  description: e.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(productsProvider),
                ),
                data: (_) => filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: searchQuery.value.isEmpty
                            ? 'No products yet'
                            : 'No results',
                        description: searchQuery.value.isEmpty
                            ? 'Tap + to add your first product'
                            : 'Try different search terms',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(productsProvider),
                        child: ListView.builder(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _ProductRow(
                                    product: filtered[i],
                                    isMobile: isMobile,
                                    onTap: () => _showEdit(
                                      context,
                                      ref,
                                      filtered[i],
                                      isMobile,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: (i * 40).ms)
                                  .slideY(begin: 0.06),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, ref, authState, isMobile),
        child: const Icon(Icons.add_rounded),
      ).animate().scale().fadeIn(delay: 300.ms),
    );
  }

  void _showAdd(
    BuildContext context,
    WidgetRef ref,
    dynamic authState,
    bool isMobile,
  ) {
    if (authState is! AuthAuthenticated || !authState.user.isAdmin) return;
    showDialog(
      context: context,
      builder: (_) => AddProductDialog(
        businessId: authState.user.businessId,
        onProductAdded: () => ref.invalidate(productsProvider),
        isMobile: isMobile,
      ),
    );
  }

  void _showEdit(
    BuildContext context,
    WidgetRef ref,
    ProductEntity product,
    bool isMobile,
  ) {
    showDialog(
      context: context,
      builder: (_) => EditProductDialog(
        product: product,
        onProductUpdated: () => ref.invalidate(productsProvider),
        isMobile: isMobile,
        businessId: '',
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _InventoryHeader extends StatelessWidget {
  final AsyncValue<List<ProductEntity>> productsAsync;
  const _InventoryHeader({required this.productsAsync});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Manage your product catalog',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: ViberantColors.outline,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ViberantColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: ViberantColors.primary,
            size: 22,
          ),
        ),
      ],
    ),
  );
}

// ─── Stat chips ───────────────────────────────────────────────────────────────
class _StatChips extends StatelessWidget {
  final int total;
  final int low;
  final int out;
  const _StatChips({required this.total, required this.low, required this.out});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Row(
      children: [
        _Chip('Total: $total', ViberantColors.primary),
        const SizedBox(width: 8),
        _Chip('Low Stock: $low', ViberantColors.warning),
        const SizedBox(width: 8),
        _Chip('Out of Stock: $out', ViberantColors.error),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
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

// ─── Search + filter bar ──────────────────────────────────────────────────────
class _SearchFilter extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onSearch;
  final String selectedCat;
  final List<String> categories;
  final ValueChanged<String> onCatChanged;

  const _SearchFilter({
    required this.ctrl,
    required this.onSearch,
    required this.selectedCat,
    required this.categories,
    required this.onCatChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'Search by name, SKU…',
              prefixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              constraints: BoxConstraints(maxHeight: 44),
            ),
          ),
        ),
        if (categories.length > 1) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCat,
                items: ['All', ...categories.where((c) => c != 'All')]
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => onCatChanged(v ?? 'All'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ─── Product row ──────────────────────────────────────────────────────────────
class _ProductRow extends StatelessWidget {
  final ProductEntity product;
  final bool isMobile;
  final VoidCallback onTap;
  const _ProductRow({
    required this.product,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stockPct = product.minStock > 0
        ? (product.stock / (product.minStock * 3)).clamp(0.0, 1.0)
        : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isMobile ? 8 : 10),
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
              width: 48,
              height: 48,
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
                      Icons.inventory_2_rounded,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip.fromStockStatus(product.stockStatus),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (product.sku != null)
                        Text(
                          '${product.sku} · ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: ViberantColors.outline,
                          ),
                        ),
                      Text(
                        product.category,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: ViberantColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Stock level bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: stockPct,
                            minHeight: 3,
                            backgroundColor: ViberantColors.outlineVariant
                                .withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation(
                              product.stockStatusColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${product.stock} units',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: ViberantColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Price column
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
                Text(
                  'Cost ₵${NumberFormat('#,###.00').format(product.costPrice)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: ViberantColors.outline,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: ViberantColors.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

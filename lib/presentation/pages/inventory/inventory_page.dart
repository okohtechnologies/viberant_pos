// lib/presentation/pages/inventory/inventory_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
// Add this import
import 'widgets/product_list_item.dart';
import 'widgets/add_product_dialog.dart';
import 'widgets/edit_product_dialog.dart';

class InventoryPage extends HookConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final authState = ref.watch(authProvider);

    // Use MediaQuery for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Filter products based on search and category
    final filteredProducts = productsAsync.when(
      data: (products) {
        return products.where((product) {
          final matchesSearch =
              product.name.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ) ||
              product.description.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ) ||
              (product.sku?.toLowerCase().contains(
                    searchQuery.value.toLowerCase(),
                  ) ??
                  false);

          final matchesCategory =
              selectedCategory == 'All' || product.category == selectedCategory;

          return matchesSearch && matchesCategory;
        }).toList();
      },
      loading: () => <ProductEntity>[],
      error: (error, stack) => <ProductEntity>[],
    );

    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Stats
            _InventoryHeader(isMobile: isMobile),

            // Search and Filters
            _SearchAndFilterSection(
              searchController: searchController,
              searchQuery: searchQuery.value,
              onSearchChanged: (value) => searchQuery.value = value,
              selectedCategory: selectedCategory,
              categories: categoriesAsync.value ?? [],
              onCategoryChanged: (category) =>
                  ref.read(selectedCategoryProvider.notifier).state = category,
              isMobile: isMobile,
            ),

            // Products List
            Expanded(
              child: productsAsync.when(
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error, ref),
                data: (products) =>
                    _buildProductsList(filteredProducts, ref, isMobile),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: Container(
        margin: EdgeInsets.only(
          bottom: isMobile ? 16 : 0,
        ), // Add bottom margin on mobile
        child: FloatingActionButton(
          onPressed: () =>
              _showAddProductDialog(context, ref, authState, isMobile),
          backgroundColor: ViberantColors.primary,
          foregroundColor: Colors.white,
          child: Icon(Icons.add_rounded),
        ).animate().scale().fadeIn(),
      ),
    );
  }

  Widget _buildProductsList(
    List<ProductEntity> filteredProducts,
    WidgetRef ref,
    bool isMobile,
  ) {
    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productsProvider);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return ProductListItem(
            product: product,
            onTap: () =>
                _showEditProductDialog(context, ref, product, isMobile),
            onStockUpdate: (newStock) => _updateStock(ref, product, newStock),
            isMobile: isMobile,
          ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: ViberantColors.primary),
          SizedBox(height: 16),
          Text(
            'Loading Products...',
            style: GoogleFonts.inter(color: ViberantColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: ViberantColors.error),
          SizedBox(height: 16),
          Text(
            'Failed to load products',
            style: GoogleFonts.inter(color: ViberantColors.error),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: GoogleFonts.inter(color: ViberantColors.grey),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(productsProvider),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: ViberantColors.grey.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'No Products Found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ViberantColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Add your first product to get started',
              style: GoogleFonts.inter(
                color: ViberantColors.grey.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    bool isMobile,
  ) {
    if (authState is! AuthAuthenticated) return;

    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        businessId: authState.user.id,
        onProductAdded: () => ref.invalidate(productsProvider),
        isMobile: isMobile,
      ),
    );
  }

  void _showEditProductDialog(
    BuildContext context,
    WidgetRef ref,
    ProductEntity product,
    bool isMobile,
  ) {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    showDialog(
      context: context,
      builder: (context) => EditProductDialog(
        product: product,
        businessId: authState.user.id,
        onProductUpdated: () => ref.invalidate(productsProvider),
        isMobile: isMobile,
      ),
    );
  }

  void _updateStock(WidgetRef ref, ProductEntity product, int newStock) {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final productRepository = ref.read(productRepositoryProvider);
    productRepository.updateStock(authState.user.id, product.id, newStock);
  }
}

// Inventory Header with Stats - Responsive
class _InventoryHeader extends ConsumerWidget {
  final bool isMobile;

  const _InventoryHeader({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final outOfStockAsync = ref.watch(outOfStockProductsProvider);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        border: Border(
          bottom: BorderSide(color: ViberantColors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            title: 'Total',
            value: productsAsync.maybeWhen(
              data: (products) => products.length.toString(),
              orElse: () => '0',
            ),
            color: ViberantColors.primary,
            isMobile: isMobile,
          ),
          _StatItem(
            title: 'Low Stock',
            value: lowStockAsync.maybeWhen(
              data: (products) => products.length.toString(),
              orElse: () => '0',
            ),
            color: ViberantColors.warning,
            isMobile: isMobile,
          ),
          _StatItem(
            title: 'Out of Stock',
            value: outOfStockAsync.maybeWhen(
              data: (products) => products.length.toString(),
              orElse: () => '0',
            ),
            color: ViberantColors.error,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isMobile;

  const _StatItem({
    required this.title,
    required this.value,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: isMobile ? 6 : 8,
          height: isMobile ? 6 : 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: ViberantColors.onSurface,
          ),
        ),
        SizedBox(height: 2),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 10 : 12,
            color: ViberantColors.grey,
          ),
        ),
      ],
    );
  }
}

// Search and Filter Section - Responsive
class _SearchAndFilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onCategoryChanged;
  final bool isMobile;

  const _SearchAndFilterSection({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        border: Border(
          bottom: BorderSide(color: ViberantColors.grey.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: isMobile ? 44 : 48,
            decoration: BoxDecoration(
              color: ViberantColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search products...",
                hintStyle: GoogleFonts.inter(
                  color: ViberantColors.grey,
                  fontSize: isMobile ? 14 : 16,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: ViberantColors.grey,
                  size: isMobile ? 20 : 24,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 12 : 0,
                ),
              ),
            ),
          ),

          SizedBox(height: isMobile ? 8 : 12),

          // Category Filter - Scrollable on mobile
          SizedBox(
            height: isMobile ? 36 : 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(
                  width: isMobile ? 4 : 0,
                ), // Add small padding on mobile
                _CategoryChip(
                  category: 'All',
                  isSelected: selectedCategory == 'All',
                  onTap: () => onCategoryChanged('All'),
                  isMobile: isMobile,
                ),
                ...categories.map(
                  (category) => _CategoryChip(
                    category: category,
                    isSelected: selectedCategory == category,
                    onTap: () => onCategoryChanged(category),
                    isMobile: isMobile,
                  ),
                ),
                SizedBox(
                  width: isMobile ? 4 : 0,
                ), // Add small padding on mobile
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMobile;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: isMobile ? 6 : 8),
      child: ChoiceChip(
        label: Text(
          category,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: ViberantColors.primary,
        labelStyle: GoogleFonts.inter(
          color: isSelected ? Colors.white : ViberantColors.grey,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 4 : 8,
        ),
      ),
    );
  }
}

// lib/presentation/pages/products/products_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';
import 'package:viberant_pos/domain/entities/product_entity.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart';
import 'package:viberant_pos/presentation/providers/products_filter_provider.dart';
import 'package:viberant_pos/presentation/widgets/pos/category_filter.dart';
import '../../pages/inventory/widgets/products_list_item_widget.dart';

class ProductsPage extends ConsumerStatefulWidget {
  final String businessId;

  const ProductsPage({super.key, required this.businessId});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  late List<String> _availableCategories = ['All'];

  @override
  void initState() {
    super.initState();
    // Load categories after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategories() {
    // Watch the products provider to get categories
    final productsAsync = ref.watch(
      filteredProductsProvider(
        ProductsFilterParams(
          businessId: widget.businessId,
          searchQuery: '',
          category: null,
        ),
      ),
    );

    // Extract categories when data is available
    productsAsync.when(
      data: (products) {
        final categories = products
            .map((p) => p.category)
            .where((cat) => cat.isNotEmpty && cat != 'General')
            .toSet()
            .toList();

        categories.sort();

        if (mounted) {
          setState(() {
            _availableCategories = ['All', ...categories];
          });
        }
      },
      loading: () {
        // Keep showing loading or current categories
      },
      error: (error, stack) {
        print('❌ Error loading categories: $error');
        if (mounted) {
          setState(() {
            _availableCategories = ['All'];
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);

    // Get filtered products
    final productsAsync = ref.watch(
      filteredProductsProvider(
        ProductsFilterParams(
          businessId: widget.businessId,
          searchQuery: _searchQuery,
          category: _selectedCategory == 'All' ? null : _selectedCategory,
        ),
      ),
    );

    // Get products for stock indicator (without filters)
    final allProductsAsync = ref.watch(
      filteredProductsProvider(
        ProductsFilterParams(
          businessId: widget.businessId,
          searchQuery: '',
          category: null,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: Column(
        children: [
          // App Bar with Search
          _buildAppBar(context, allProductsAsync),

          // Category Filter
          CategoryFilter(
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            categories: _availableCategories,
            isMobile: isMobile,
          ),

          // Products List
          Expanded(
            child: productsAsync.when(
              data: (products) => _buildProductsList(products, authState),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, authState),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    AsyncValue<List<ProductEntity>> productsAsync,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + (isMobile ? 12 : 16),
        left: isMobile ? 16 : 20,
        right: isMobile ? 16 : 20,
        bottom: isMobile ? 16 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: ViberantColors.onSurface,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w700,
                        color: ViberantColors.onSurface,
                      ),
                    ),
                    Text(
                      'Browse and manage inventory',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        color: ViberantColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Stock indicator using the AsyncValue directly
              productsAsync.when(
                data: (products) {
                  final lowStockCount = products
                      .where((p) => p.isLowStock)
                      .length;
                  if (lowStockCount == 0) return const SizedBox();

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ViberantColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: ViberantColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$lowStockCount low',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ViberantColors.warning,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: ViberantColors.background,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              border: Border.all(
                color: ViberantColors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products by name or category...',
                hintStyle: GoogleFonts.inter(
                  fontSize: isMobile ? 14 : 16,
                  color: ViberantColors.grey,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: ViberantColors.grey,
                  size: isMobile ? 20 : 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          size: isMobile ? 20 : 24,
                        ),
                        color: ViberantColors.grey,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                color: ViberantColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<ProductEntity> products, AuthState authState) {
    if (products.isEmpty) {
      return _buildEmptyState(authState);
    }

    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate the provider to refresh data
        ref.invalidate(
          filteredProductsProvider(
            ProductsFilterParams(
              businessId: widget.businessId,
              searchQuery: _searchQuery,
              category: _selectedCategory == 'All' ? null : _selectedCategory,
            ),
          ),
        );
        // Also reload categories
        _loadCategories();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductListItem(
            product: products[index],
            isAdmin: isAdmin,
            onTap: () => _showProductDetails(context, products[index]),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: ViberantColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Image placeholder
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ViberantColors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: ViberantColors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 120,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: ViberantColors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 14,
                            width: 60,
                            decoration: BoxDecoration(
                              color: ViberantColors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 20,
                            width: 40,
                            decoration: BoxDecoration(
                              color: ViberantColors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
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
        );
      },
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: ViberantColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load products',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ViberantColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().split(':').last.trim(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ViberantColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(
                  filteredProductsProvider(
                    ProductsFilterParams(
                      businessId: widget.businessId,
                      searchQuery: _searchQuery,
                      category: _selectedCategory == 'All'
                          ? null
                          : _selectedCategory,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ViberantColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AuthState authState) {
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: ViberantColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: ViberantColors.grey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No products found for "$_searchQuery"'
                  : 'No products available',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ViberantColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term or category'
                  : 'Add your first product to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ViberantColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && isAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddProductModal(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ViberantColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, AuthState authState) {
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    if (!isAdmin) return const SizedBox();

    return FloatingActionButton.extended(
      onPressed: () => _showAddProductModal(context),
      backgroundColor: ViberantColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Add Product',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showAddProductModal(BuildContext context) {
    // TODO: Implement add product modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: const Text('Add product functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context, ProductEntity product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ViberantColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ViberantColors.background,
                  borderRadius: BorderRadius.circular(16),
                  image: product.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.inventory_2_rounded,
                          size: 64,
                          color: ViberantColors.grey.withOpacity(0.3),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 20),

              // Product Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: ViberantColors.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: product.stockStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.stockStatus,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: product.stockStatusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: ViberantColors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // Product Details
              _buildDetailRow(
                'Price',
                '₵${NumberFormat('#,###.00').format(product.price)}',
              ),
              _buildDetailRow('Stock', '${product.stock} units'),
              _buildDetailRow('Min Stock Alert', '${product.minStock} units'),
              if (product.category.isNotEmpty)
                _buildDetailRow('Category', product.category),
              if (product.supplier != null)
                _buildDetailRow('Supplier', product.supplier!),
              if (product.barcode != null && product.barcode!.isNotEmpty)
                _buildDetailRow('Barcode', product.barcode!),

              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: ViberantColors.grey),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ViberantColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

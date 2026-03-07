// lib/features/pos/presentation/pages/pos_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/states/auth_state.dart';
import '../../../../presentation/providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/products_provider.dart';
import '../../widgets/pos/cart_panel.dart';
import '../../widgets/pos/category_filter.dart';

class PosPage extends HookConsumerWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedCategory = useState('All');

    // Get products from Firebase - this will be empty if not authenticated
    final productsAsync = ref.watch(productsProvider);

    // Check if user is authenticated
    final authState = ref.watch(authProvider);

    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768; // Tablet breakpoint
    final isSmallMobile = screenWidth < 400;

    // Show login prompt if not authenticated
    if (authState is! AuthAuthenticated) {
      return _buildNotAuthenticatedState(isMobile);
    }

    // Handle loading state
    if (productsAsync.isLoading) {
      return _buildLoadingState(isMobile);
    }

    // Handle error state
    if (productsAsync.hasError) {
      return _buildErrorState(
        productsAsync.error ?? 'Unknown error',
        ref,
        isMobile,
      );
    }

    // Get products or empty list
    final products = productsAsync.value ?? [];

    final filteredProducts = products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          product.description.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );
      final matchesCategory =
          selectedCategory.value == 'All' ||
          product.category == selectedCategory.value;
      return matchesSearch && matchesCategory && product.stock > 0;
    }).toList();

    // Get unique categories from products
    final categories = ['All', ...products.map((p) => p.category).toSet()];

    // For mobile, use vertical layout; for desktop, use horizontal layout
    if (isMobile) {
      return _buildMobileLayout(
        context,
        searchController,
        searchQuery,
        selectedCategory,
        categories,
        filteredProducts,
        isSmallMobile,
      );
    } else {
      return _buildDesktopLayout(
        searchController,
        searchQuery,
        selectedCategory,
        categories,
        filteredProducts,
      );
    }
  }

  Widget _buildMobileLayout(
    BuildContext context,
    TextEditingController searchController,
    ValueNotifier<String> searchQuery,
    ValueNotifier<String> selectedCategory,
    List<String> categories,
    List<ProductEntity> filteredProducts,
    bool isSmallMobile,
  ) {
    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search - Mobile
            _PosHeader(
              searchController: searchController,
              onSearchChanged: (value) => searchQuery.value = value,
              isMobile: true,
              isSmallMobile: isSmallMobile,
            ),

            // Category Filter - Mobile
            CategoryFilter(
              selectedCategory: selectedCategory.value,
              onCategorySelected: (category) =>
                  selectedCategory.value = category,
              categories: categories,
              isMobile: true,
            ),

            // Products Grid - Mobile
            Expanded(
              child: filteredProducts.isEmpty
                  ? _EmptyProductsState(
                      searchQuery: searchQuery.value,
                      isMobile: true,
                    )
                  : _ProductsGrid(
                      products: filteredProducts,
                      isMobile: true,
                      isSmallMobile: isSmallMobile,
                    ),
            ),

            // Cart Panel as Bottom Sheet for Mobile
            _MobileCartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    TextEditingController searchController,
    ValueNotifier<String> searchQuery,
    ValueNotifier<String> selectedCategory,
    List<String> categories,
    List<ProductEntity> filteredProducts,
  ) {
    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: SafeArea(
        child: Row(
          children: [
            // Products Section - Desktop
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Header with Search - Desktop
                  _PosHeader(
                    searchController: searchController,
                    onSearchChanged: (value) => searchQuery.value = value,
                    isMobile: false,
                    isSmallMobile: false,
                  ),

                  // Category Filter - Desktop
                  CategoryFilter(
                    selectedCategory: selectedCategory.value,
                    onCategorySelected: (category) =>
                        selectedCategory.value = category,
                    categories: categories,
                    isMobile: false,
                  ),

                  // Products Grid - Desktop
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? _EmptyProductsState(
                            searchQuery: searchQuery.value,
                            isMobile: false,
                          )
                        : _ProductsGrid(
                            products: filteredProducts,
                            isMobile: false,
                            isSmallMobile: false,
                          ),
                  ),
                ],
              ),
            ),

            // Cart Panel - Desktop
            const Expanded(flex: 2, child: CartPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAuthenticatedState(bool isMobile) {
    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 24 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.login_rounded,
                  size: isMobile ? 48 : 64,
                  color: ViberantColors.grey.withOpacity(0.5),
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Text(
                  'Please Sign In',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w600,
                    color: ViberantColors.grey,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Text(
                  'You need to be signed in to access the POS',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 14 : 16,
                    color: ViberantColors.grey.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 20 : 32),
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to login page
                    },
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.inter(fontSize: isMobile ? 16 : 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isMobile) {
    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: ViberantColors.primary),
              SizedBox(height: isMobile ? 16 : 24),
              Text(
                'Loading Products...',
                style: GoogleFonts.inter(
                  color: ViberantColors.grey,
                  fontSize: isMobile ? 16 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, WidgetRef ref, bool isMobile) {
    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 24 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: isMobile ? 48 : 64,
                  color: ViberantColors.error,
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Text(
                  'Failed to load products',
                  style: GoogleFonts.inter(
                    color: ViberantColors.error,
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Text(
                  error.toString(),
                  style: GoogleFonts.inter(
                    color: ViberantColors.grey,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 20 : 32),
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: ElevatedButton(
                    onPressed: () => ref.invalidate(productsProvider),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(fontSize: isMobile ? 16 : 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Mobile Cart Button (Shows cart as bottom sheet)
class _MobileCartButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartSummary = ref.watch(cartSummaryProvider);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        border: Border(
          top: BorderSide(color: ViberantColors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Cart Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cartSummary.totalItems} items',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ViberantColors.onSurface,
                  ),
                ),
                Text(
                  'GHS ${NumberFormat('#,###.00').format(cartSummary.totalAmount)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ViberantColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // View Cart Button
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: CartPanel(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ViberantColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'View Cart',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Empty Products State
class _EmptyProductsState extends StatelessWidget {
  final String searchQuery;
  final bool isMobile;

  const _EmptyProductsState({
    required this.searchQuery,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: isMobile ? 48 : 64,
              color: ViberantColors.grey.withOpacity(0.3),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              searchQuery.isEmpty
                  ? "No Products Available"
                  : "No Products Found",
              style: GoogleFonts.inter(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: ViberantColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              searchQuery.isEmpty
                  ? "Add products to your inventory to get started"
                  : "Try searching with different terms",
              style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                color: ViberantColors.grey.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Products Grid with Horizontal Layout
class _ProductsGrid extends StatelessWidget {
  final List<ProductEntity> products;
  final bool isMobile;
  final bool isSmallMobile;

  const _ProductsGrid({
    required this.products,
    required this.isMobile,
    required this.isSmallMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _buildMobileList();
    } else {
      return _buildDesktopGrid();
    }
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: isSmallMobile ? 8 : 12),
          child: _HorizontalProductCard(
            product: products[index],
            isMobile: true,
            isSmallMobile: isSmallMobile,
          ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0),
        );
      },
    );
  }

  Widget _buildDesktopGrid() {
    final crossAxisCount = 3; // Reduced for better horizontal layout
    final padding = 16.0;
    final spacing = 12.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.8, // Horizontal aspect ratio
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _HorizontalProductCard(
            product: products[index],
            isMobile: false,
            isSmallMobile: false,
          ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

// Horizontal Product Card
class _HorizontalProductCard extends ConsumerWidget {
  final ProductEntity product;
  final bool isMobile;
  final bool isSmallMobile;

  const _HorizontalProductCard({
    required this.product,
    required this.isMobile,
    required this.isSmallMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartItem = cart.firstWhereOrNull(
      (item) => item.product.id == product.id,
    );
    final quantityInCart = cartItem?.quantity ?? 0;

    return Material(
      color: ViberantColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _addToCart(ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Image/Icon
              _buildProductImage(),

              // Product Info
              Expanded(child: _buildProductInfo()),

              // Price and Add Button
              _buildPriceAndAction(quantityInCart, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final size = isMobile ? 60.0 : 80.0;

    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: ViberantColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.shopping_bag_rounded,
        color: ViberantColors.primary,
        size: isMobile ? 24 : 32,
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 8 : 12,
        horizontal: isMobile ? 4 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Product Name
          Text(
            product.name,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: ViberantColors.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: isMobile ? 2 : 4),

          // Product Description
          Text(
            product.description,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 11 : 12,
              color: ViberantColors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: isMobile ? 4 : 6),

          // Stock Status
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 8,
              vertical: isMobile ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: product.stockStatusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: product.stockStatusColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              '${product.stock} in stock',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.w500,
                color: product.stockStatusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndAction(int quantityInCart, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Price
          Text(
            'GHS ${NumberFormat('#,###.00').format(product.price)}',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: ViberantColors.primary,
            ),
          ),

          SizedBox(height: isMobile ? 4 : 8),

          // Add to Cart Button or Quantity Indicator
          if (quantityInCart == 0)
            Container(
              width: isMobile ? 28 : 32,
              height: isMobile ? 28 : 32,
              decoration: BoxDecoration(
                color: ViberantColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: isMobile ? 16 : 18,
              ),
            ).animate().scale(duration: 300.ms).fadeIn()
          else
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: ViberantColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                quantityInCart.toString(),
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ).animate().scale(duration: 300.ms),
        ],
      ),
    );
  }

  void _addToCart(WidgetRef ref) {
    if (product.stock > 0) {
      ref.read(cartProvider.notifier).addProduct(product);
    }
  }
}

// POS Header
class _PosHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool isMobile;
  final bool isSmallMobile;

  const _PosHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.isMobile,
    required this.isSmallMobile,
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
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
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
                  ),
                ),
              ),
            ),
          ),

          if (!isSmallMobile) ...[
            SizedBox(width: isMobile ? 12 : 16),

            // Quick Actions (hidden on very small screens)
            Row(
              children: [
                _HeaderAction(
                  icon: Icons.qr_code_scanner_rounded,
                  label: "Scan",
                  onTap: () {},
                  isMobile: isMobile,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                _HeaderAction(
                  icon: Icons.receipt_long_rounded,
                  label: "Recent",
                  onTap: () {},
                  isMobile: isMobile,
                ),
                if (!isMobile) ...[
                  SizedBox(width: 12),
                  _HeaderAction(
                    icon: Icons.people_rounded,
                    label: "Customers",
                    onTap: () {},
                    isMobile: isMobile,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Header Action Button
class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isMobile;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: ViberantColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: isMobile ? 16 : 18, color: ViberantColors.primary),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w500,
                color: ViberantColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

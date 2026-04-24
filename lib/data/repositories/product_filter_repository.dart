// lib/data/repositories/product_filter_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:viberant_pos/domain/entities/product_entity.dart';

class ProductFilterRepository {
  final FirebaseFirestore _firestore;

  ProductFilterRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get filtered products stream with search and category
  Stream<List<ProductEntity>> getFilteredProductsStream({
    required String businessId,
    String? searchQuery,
    String? category,
  }) {
    debugPrint('🔄 Getting filtered products stream for business: $businessId');
    debugPrint('   Search: $searchQuery, Category: $category');

    // Start with base query
    Query query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true);

    // Apply category filter if provided and not "All"
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    // Always order by name for consistency
    query = query.orderBy('name');

    return query
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList();

          // Apply search filter locally if provided
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final searchLower = searchQuery.toLowerCase();
            products = products.where((product) {
              return product.name.toLowerCase().contains(searchLower) ||
                  product.description.toLowerCase().contains(searchLower) ||
                  product.category.toLowerCase().contains(searchLower) ||
                  (product.barcode?.toLowerCase().contains(searchLower) ??
                      false) ||
                  (product.sku?.toLowerCase().contains(searchLower) ?? false) ||
                  (product.supplier?.toLowerCase().contains(searchLower) ??
                      false);
            }).toList();
          }

          debugPrint(
            '📦 Filtered products stream update: ${products.length} products',
          );
          return products;
        })
        .handleError((error) {
          debugPrint('❌ Filtered products stream error: $error');
          throw error;
        });
  }

  // Get categories with product count
  Stream<List<Map<String, dynamic>>> getCategoriesWithCount(String businessId) {
    debugPrint('📂 Getting categories with count for business: $businessId');

    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final categories = <String, int>{};

          for (final doc in snapshot.docs) {
            final category = doc.data()['category'] as String? ?? 'General';
            categories[category] = (categories[category] ?? 0) + 1;
          }

          // Convert to list of maps and sort by name
          final result = categories.entries
              .map((entry) => {'name': entry.key, 'count': entry.value})
              .toList();

          // Add "All" category with total count
          result.insert(0, {'name': 'All', 'count': snapshot.docs.length});

          debugPrint('📂 Found ${result.length} categories');
          return result;
        })
        .handleError((error) {
          debugPrint('❌ Categories with count error: $error');
          throw error;
        });
  }

  // Search products with multiple criteria (all filtering done locally)
  Stream<List<ProductEntity>> searchProductsWithFilters({
    required String businessId,
    String? nameQuery,
    String? category,
    double? minPrice,
    double? maxPrice,
    int? minStock,
    int? maxStock,
  }) {
    debugPrint('🔍 Advanced search for business: $businessId');
    debugPrint('   Name: $nameQuery, Category: $category');
    debugPrint('   Price: $minPrice - $maxPrice, Stock: $minStock - $maxStock');

    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList();

          // Apply name search filter
          if (nameQuery != null && nameQuery.isNotEmpty) {
            final searchLower = nameQuery.toLowerCase();
            products = products.where((product) {
              return product.name.toLowerCase().contains(searchLower) ||
                  product.description.toLowerCase().contains(searchLower) ||
                  product.category.toLowerCase().contains(searchLower) ||
                  (product.barcode?.toLowerCase().contains(searchLower) ??
                      false) ||
                  (product.sku?.toLowerCase().contains(searchLower) ?? false) ||
                  (product.supplier?.toLowerCase().contains(searchLower) ??
                      false);
            }).toList();
          }

          // Apply category filter
          if (category != null && category.isNotEmpty && category != 'All') {
            products = products
                .where((product) => product.category == category)
                .toList();
          }

          // Apply price range filter
          if (minPrice != null) {
            products = products
                .where((product) => product.price >= minPrice)
                .toList();
          }
          if (maxPrice != null) {
            products = products
                .where((product) => product.price <= maxPrice)
                .toList();
          }

          // Apply stock range filter
          if (minStock != null) {
            products = products
                .where((product) => product.stock >= minStock)
                .toList();
          }
          if (maxStock != null) {
            products = products
                .where((product) => product.stock <= maxStock)
                .toList();
          }

          debugPrint('🔍 Advanced search found: ${products.length} products');
          return products;
        })
        .handleError((error) {
          debugPrint('❌ Advanced search error: $error');
          throw error;
        });
  }

  // In ProductFilterRepository class
  Future<List<ProductEntity>> getProductsOnce({
    required String businessId,
    String? searchQuery,
    String? category,
  }) async {
    debugPrint('📋 Getting products once for business: $businessId');

    Query query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('name');

    final snapshot = await query.get();

    var products = snapshot.docs
        .map((doc) => ProductEntity.fromFirestore(doc))
        .toList();

    // Apply search filter locally if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      products = products.where((product) {
        return product.name.toLowerCase().contains(searchLower) ||
            product.description.toLowerCase().contains(searchLower) ||
            product.category.toLowerCase().contains(searchLower) ||
            (product.barcode?.toLowerCase().contains(searchLower) ?? false) ||
            (product.sku?.toLowerCase().contains(searchLower) ?? false) ||
            (product.supplier?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    debugPrint('📋 Found ${products.length} products');
    return products;
  }

  // Get low stock products with optional category filter
  Stream<List<ProductEntity>> getLowStockProducts({
    required String businessId,
    int? threshold,
    String? category,
  }) {
    final lowStockThreshold = threshold ?? 10;

    debugPrint('⚠️ Getting low stock products (threshold: $lowStockThreshold)');

    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList();

          // Apply low stock filter
          products = products
              .where((product) => product.stock < lowStockThreshold)
              .toList();

          // Apply category filter if provided
          if (category != null && category.isNotEmpty && category != 'All') {
            products = products
                .where((product) => product.category == category)
                .toList();
          }

          // Sort by stock level (lowest first)
          products.sort((a, b) => a.stock.compareTo(b.stock));

          debugPrint('⚠️ Found ${products.length} low stock products');
          return products;
        })
        .handleError((error) {
          debugPrint('❌ Low stock products error: $error');
          throw error;
        });
  }

  // Get products by price range
  Stream<List<ProductEntity>> getProductsByPriceRange({
    required String businessId,
    required double minPrice,
    required double maxPrice,
    String? category,
  }) {
    debugPrint('💰 Getting products by price range: $minPrice - $maxPrice');

    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList();

          // Apply price range filter
          products = products
              .where(
                (product) =>
                    product.price >= minPrice && product.price <= maxPrice,
              )
              .toList();

          // Apply category filter if provided
          if (category != null && category.isNotEmpty && category != 'All') {
            products = products
                .where((product) => product.category == category)
                .toList();
          }

          // Sort by price
          products.sort((a, b) => a.price.compareTo(b.price));

          debugPrint('💰 Found ${products.length} products in price range');
          return products;
        })
        .handleError((error) {
          debugPrint('❌ Products by price range error: $error');
          throw error;
        });
  }

  // Get statistics for dashboard
  Future<Map<String, dynamic>> getProductStats(String businessId) async {
    debugPrint('📊 Getting product statistics for business: $businessId');

    try {
      // Get all active products
      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      final products = snapshot.docs
          .map((doc) => ProductEntity.fromFirestore(doc))
          .toList();

      // Calculate statistics
      final totalProducts = products.length;
      final lowStockProducts = products.where((p) => p.isLowStock).length;
      final outOfStockProducts = products.where((p) => p.isOutOfStock).length;

      // Get unique categories
      final categories = products.map((p) => p.category).toSet();

      // Calculate total inventory value
      double totalValue = 0;
      for (final product in products) {
        totalValue += product.price * product.stock;
      }

      // Calculate average stock
      final averageStock = totalProducts > 0
          ? products.map((p) => p.stock).reduce((a, b) => a + b) / totalProducts
          : 0;

      // Calculate total profit potential
      double totalProfitPotential = 0;
      for (final product in products) {
        totalProfitPotential += product.profitMargin * product.stock;
      }

      final stats = {
        'totalProducts': totalProducts,
        'lowStockProducts': lowStockProducts,
        'outOfStockProducts': outOfStockProducts,
        'totalCategories': categories.length,
        'totalInventoryValue': totalValue,
        'totalProfitPotential': totalProfitPotential,
        'averageStock': averageStock,
        'categories': categories.toList(),
      };

      debugPrint('📊 Product statistics: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ Product statistics error: $e');
      throw Exception('Failed to get product statistics: $e');
    }
  }

  // Get recently updated products
  Stream<List<ProductEntity>> getRecentlyUpdatedProducts(
    String businessId, {
    int limit = 10,
  }) {
    debugPrint('🕒 Getting recently updated products (limit: $limit)');

    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList();

          // Sort by updatedAt (most recent first)
          products.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          // Take limit
          final recentProducts = products.take(limit).toList();

          debugPrint(
            '🕒 Found ${recentProducts.length} recently updated products',
          );
          return recentProducts;
        })
        .handleError((error) {
          debugPrint('❌ Recently updated products error: $error');
          throw error;
        });
  }

  // Get products with highest profit margin
  Stream<List<ProductEntity>> getHighProfitProducts(
    String businessId, {
    int limit = 10,
  }) {
    debugPrint('💰 Getting high profit margin products');

    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList();

          // Calculate profit margin and sort
          products.sort((a, b) {
            final marginA = a.profitMarginPercentage;
            final marginB = b.profitMarginPercentage;
            return marginB.compareTo(marginA); // Descending order
          });

          final highProfitProducts = products.take(limit).toList();
          debugPrint(
            '💰 Found ${highProfitProducts.length} high profit products',
          );
          return highProfitProducts;
        })
        .handleError((error) {
          debugPrint('❌ High profit products error: $error');
          throw error;
        });
  }

  // Get all unique categories
  Future<List<String>> getAllCategories(String businessId) async {
    debugPrint('📂 Getting all categories for business: $businessId');

    try {
      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      final categories = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return data['category'] as String? ?? 'General';
          })
          .toSet()
          .toList();

      categories.sort();
      categories.insert(0, 'All');

      debugPrint('📂 Found ${categories.length} categories');
      return categories;
    } catch (e) {
      debugPrint('❌ Get all categories error: $e');
      throw Exception('Failed to get categories: $e');
    }
  }
}

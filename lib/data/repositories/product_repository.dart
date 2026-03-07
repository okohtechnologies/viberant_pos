// lib/data/repositories/product_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_entity.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get products stream for real-time updates
  Stream<List<ProductEntity>> getProductsStream(String businessId) {
    print('🔄 Getting products stream for business: $businessId');

    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          print('📦 Products stream update: ${snapshot.docs.length} products');
          return snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList();
        })
        .handleError((error) {
          print('❌ Products stream error: $error');
          throw error;
        });
  }

  // Get all products (including inactive)
  Stream<List<ProductEntity>> getAllProducts(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList(),
        )
        .handleError((error) {
          print('❌ All products error: $error');
          throw error;
        });
  }

  // Get low stock products
  Stream<List<ProductEntity>> getLowStockProducts(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('stock', isLessThan: 10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList(),
        )
        .handleError((error) {
          print('❌ Low stock products error: $error');
          throw error;
        });
  }

  // Get out of stock products
  Stream<List<ProductEntity>> getOutOfStockProducts(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('stock', isEqualTo: 0)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList(),
        )
        .handleError((error) {
          print('❌ Out of stock products error: $error');
          throw error;
        });
  }

  // Add new product
  Future<void> addProduct(String businessId, ProductEntity product) async {
    try {
      print('➕ Adding product: ${product.name} to business: $businessId');

      final productData = product.toMap();
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .doc(product.id)
          .set(productData);

      print('✅ Product added successfully: ${product.name}');
    } catch (e) {
      print('❌ Failed to add product: $e');
      throw Exception('Failed to add product: $e');
    }
  }

  // Update product
  Future<void> updateProduct(String businessId, ProductEntity product) async {
    try {
      print('🔄 Updating product: ${product.name}');

      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .doc(product.id)
          .update(updatedProduct.toMap());

      print('✅ Product updated successfully: ${product.name}');
    } catch (e) {
      print('❌ Failed to update product: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(String businessId, String productId) async {
    try {
      print('🗑️ Soft deleting product: $productId');

      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .doc(productId)
          .update({'isActive': false, 'updatedAt': Timestamp.now()});

      print('✅ Product soft deleted: $productId');
    } catch (e) {
      print('❌ Failed to delete product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  // Update product stock
  Future<void> updateStock(
    String businessId,
    String productId,
    int newStock,
  ) async {
    try {
      print('📦 Updating stock for product: $productId to $newStock');

      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .doc(productId)
          .update({'stock': newStock, 'updatedAt': Timestamp.now()});

      print('✅ Stock updated successfully');
    } catch (e) {
      print('❌ Failed to update stock: $e');
      throw Exception('Failed to update stock: $e');
    }
  }

  // Search products - FIXED VERSION
  Future<List<ProductEntity>> searchProducts(
    String businessId,
    String query,
  ) async {
    try {
      print('🔍 Searching products for: "$query" in business: $businessId');

      if (query.isEmpty) {
        // Return all active products if query is empty
        return await getProducts(businessId);
      }

      // Convert query to lowercase for case-insensitive search
      final searchQuery = query.toLowerCase();

      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .where('searchKeywords', arrayContains: searchQuery)
          .get();

      print('🔍 Search found: ${snapshot.docs.length} products');

      return snapshot.docs
          .map((doc) => ProductEntity.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Search products error: $e');
      throw Exception('Search failed: $e');
    }
  }

  // Get products once (for search and initial load)
  Future<List<ProductEntity>> getProducts(String businessId) async {
    try {
      print('📋 Getting products once for business: $businessId');

      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      print('📋 Found ${snapshot.docs.length} active products');

      return snapshot.docs
          .map((doc) => ProductEntity.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Get products error: $e');
      throw Exception('Failed to get products: $e');
    }
  }

  // Get product by ID
  Future<ProductEntity?> getProductById(
    String businessId,
    String productId,
  ) async {
    try {
      print('🎯 Getting product by ID: $productId');

      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .doc(productId)
          .get();

      if (doc.exists) {
        print('🎯 Product found: ${doc.data()?['name']}');
        return ProductEntity.fromFirestore(doc);
      } else {
        print('🎯 Product not found: $productId');
        return null;
      }
    } catch (e) {
      print('❌ Get product by ID error: $e');
      throw Exception('Failed to get product: $e');
    }
  }

  // Get products by category
  Stream<List<ProductEntity>> getProductsByCategory(
    String businessId,
    String category,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductEntity.fromFirestore(doc))
              .toList(),
        )
        .handleError((error) {
          print('❌ Products by category error: $error');
          throw error;
        });
  }

  // Get categories
  Future<List<String>> getCategories(String businessId) async {
    try {
      print('📂 Getting categories for business: $businessId');

      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String? ?? 'General')
          .toSet()
          .toList();

      categories.sort();

      print('📂 Found ${categories.length} categories: $categories');

      return categories;
    } catch (e) {
      print('❌ Get categories error: $e');
      throw Exception('Failed to get categories: $e');
    }
  }

  // Bulk update products (for imports)
  Future<void> bulkUpdateProducts(
    String businessId,
    List<ProductEntity> products,
  ) async {
    try {
      print('📦 Bulk updating ${products.length} products');

      final batch = _firestore.batch();

      for (final product in products) {
        final productRef = _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('products')
            .doc(product.id);

        batch.set(productRef, product.toMap());
      }

      await batch.commit();
      print('✅ Bulk update completed successfully');
    } catch (e) {
      print('❌ Bulk update error: $e');
      throw Exception('Bulk update failed: $e');
    }
  }

  // Check if product name already exists
  Future<bool> isProductNameUnique(
    String businessId,
    String productName, {
    String? excludeProductId,
  }) async {
    try {
      Query query = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .where('name', isEqualTo: productName)
          .where('isActive', isEqualTo: true);

      final snapshot = await query.get();

      // If we're updating a product, exclude it from the check
      if (excludeProductId != null) {
        return snapshot.docs.every((doc) => doc.id == excludeProductId);
      }

      return snapshot.docs.isEmpty;
    } catch (e) {
      print('❌ Product name uniqueness check error: $e');
      throw Exception('Failed to check product name: $e');
    }
  }
}

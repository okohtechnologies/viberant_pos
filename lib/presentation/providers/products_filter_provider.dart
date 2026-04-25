// lib/presentation/providers/product_filter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viberant_pos/data/repositories/product_filter_repository.dart';
import 'package:viberant_pos/domain/entities/product_entity.dart';

// Provider for the filter repository
final productFilterRepositoryProvider = Provider<ProductFilterRepository>((
  ref,
) {
  return ProductFilterRepository();
});

// Provider family for filtered products
final filteredProductsProvider = StreamProvider.family
    .autoDispose<List<ProductEntity>, ProductsFilterParams>((ref, params) {
      final repository = ref.read(productFilterRepositoryProvider);
      return repository.getFilteredProductsStream(
        businessId: params.businessId,
        searchQuery: params.searchQuery,
        category: params.category,
      );
    });

// Provider for categories with count
final categoriesWithCountProvider = StreamProvider.family
    .autoDispose<List<Map<String, dynamic>>, String>((ref, businessId) {
      final repository = ref.read(productFilterRepositoryProvider);
      return repository.getCategoriesWithCount(businessId);
    });

// Provider for product statistics
final productStatsProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, String>((ref, businessId) {
      final repository = ref.read(productFilterRepositoryProvider);
      return repository.getProductStats(businessId);
    });

// Provider for low stock products with filters
final filteredLowStockProductsProvider = StreamProvider.family
    .autoDispose<List<ProductEntity>, LowStockParams>((ref, params) {
      final repository = ref.read(productFilterRepositoryProvider);
      return repository.getLowStockProducts(
        businessId: params.businessId,
        threshold: params.threshold,
        category: params.category,
      );
    });

// Parameters for product filtering
class ProductsFilterParams {
  final String businessId;
  final String? searchQuery;
  final String? category;

  ProductsFilterParams({
    required this.businessId,
    this.searchQuery,
    this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductsFilterParams &&
          runtimeType == other.runtimeType &&
          businessId == other.businessId &&
          searchQuery == other.searchQuery &&
          category == other.category;

  @override
  int get hashCode =>
      businessId.hashCode ^ searchQuery.hashCode ^ category.hashCode;
}

// In your product_filter_provider.dart, add:
final filteredProductsFutureProvider = FutureProvider.family
    .autoDispose<List<ProductEntity>, ProductsFilterParams>((ref, params) {
      final repository = ref.read(productFilterRepositoryProvider);
      return repository.getProductsOnce(
        businessId: params.businessId,
        searchQuery: params.searchQuery,
        category: params.category,
      );
    });

// Parameters for low stock filtering
class LowStockParams {
  final String businessId;
  final int? threshold;
  final String? category;

  LowStockParams({required this.businessId, this.threshold, this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LowStockParams &&
          runtimeType == other.runtimeType &&
          businessId == other.businessId &&
          threshold == other.threshold &&
          category == other.category;

  @override
  int get hashCode =>
      businessId.hashCode ^ threshold.hashCode ^ category.hashCode;
}

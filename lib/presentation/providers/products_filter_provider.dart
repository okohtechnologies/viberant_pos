// lib/presentation/providers/products_filter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_filter_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/states/auth_state.dart';
import 'auth_provider.dart';

/// Parameters for filtered product queries.
/// Used as the family key — must implement == and hashCode.
class FilterParams {
  final String businessId;
  final String? searchQuery;
  final String? category;

  const FilterParams({
    required this.businessId,
    this.searchQuery,
    this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterParams &&
          other.businessId == businessId &&
          other.searchQuery == searchQuery &&
          other.category == category;

  @override
  int get hashCode =>
      businessId.hashCode ^ searchQuery.hashCode ^ category.hashCode;
}

final productFilterRepositoryProvider = Provider<ProductFilterRepository>((
  ref,
) {
  return ProductFilterRepository();
});

/// Filtered + searched products stream.
/// Auto-disposes when the screen using it leaves the tree.
final filteredProductsProvider = StreamProvider.autoDispose
    .family<List<ProductEntity>, FilterParams>((ref, params) {
      final repo = ref.read(productFilterRepositoryProvider);

      return repo.getFilteredProductsStream(
        businessId: params.businessId,
        searchQuery: params.searchQuery,
        category: params.category,
      );
    });

/// Convenience provider — current user's business products, filtered.
/// Reads businessId from auth so screens don't need to pass it.
final currentUserFilteredProductsProvider = StreamProvider.autoDispose
    .family<List<ProductEntity>, ({String? searchQuery, String? category})>((
      ref,
      params,
    ) {
      final auth = ref.watch(authProvider);
      if (auth is! AuthAuthenticated) return const Stream.empty();

      final repo = ref.read(productFilterRepositoryProvider);
      return repo.getFilteredProductsStream(
        businessId: auth.user.businessId,
        searchQuery: params.searchQuery,
        category: params.category,
      );
    });

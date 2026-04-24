// lib/presentation/providers/inventory_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart';
import 'package:viberant_pos/presentation/providers/product_repository_provider.dart';
import '../../domain/entities/product_entity.dart';

// Re-export for convenience — inventory pages import this file
export 'product_repository_provider.dart';
export 'products_provider.dart';

// Out of stock products (unique to inventory)
final outOfStockProductsProvider =
    StreamProvider.autoDispose<List<ProductEntity>>((ref) {
      final productRepository = ref.read(productRepositoryProvider);
      final authState = ref.watch(authProvider);

      if (authState is! AuthAuthenticated) return const Stream.empty();

      return productRepository.getOutOfStockProducts(authState.user.businessId);
    });

// Categories
final categoriesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final productRepository = ref.read(productRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState is! AuthAuthenticated) return Future.value([]);

  return productRepository.getCategories(authState.user.businessId);
});

// Selected category for filtering
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

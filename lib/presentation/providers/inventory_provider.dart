// lib/presentation/providers/inventory_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../domain/entities/product_entity.dart';

// Product Repository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// All active products
final productsProvider = StreamProvider.autoDispose<List<ProductEntity>>((ref) {
  final productRepository = ref.read(productRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState is! AuthAuthenticated) {
    return const Stream.empty();
  }

  return productRepository.getProductsStream(authState.user.id);
});

// Low stock products
final lowStockProductsProvider =
    StreamProvider.autoDispose<List<ProductEntity>>((ref) {
      final productRepository = ref.read(productRepositoryProvider);
      final authState = ref.watch(authProvider);

      if (authState is! AuthAuthenticated) {
        return const Stream.empty();
      }

      return productRepository.getLowStockProducts(authState.user.id);
    });

// Out of stock products
final outOfStockProductsProvider =
    StreamProvider.autoDispose<List<ProductEntity>>((ref) {
      final productRepository = ref.read(productRepositoryProvider);
      final authState = ref.watch(authProvider);

      if (authState is! AuthAuthenticated) {
        return const Stream.empty();
      }

      return productRepository.getOutOfStockProducts(authState.user.id);
    });

// Categories
final categoriesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final productRepository = ref.read(productRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState is! AuthAuthenticated) {
    return Future.value([]);
  }

  return productRepository.getCategories(authState.user.id);
});

// Selected category for filtering
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

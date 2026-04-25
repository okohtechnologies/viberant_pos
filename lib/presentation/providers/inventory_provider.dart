import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/states/auth_state.dart';
import 'auth_provider.dart';
import 'product_repository_provider.dart';

export 'product_repository_provider.dart';
export 'products_provider.dart';

final outOfStockProductsProvider =
    StreamProvider.autoDispose<List<ProductEntity>>((ref) {
      final repo = ref.read(productRepositoryProvider);
      final authState = ref.watch(authProvider);

      if (authState is! AuthAuthenticated) return const Stream.empty();
      return repo.getOutOfStockProducts(authState.user.businessId);
    });

final categoriesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final repo = ref.read(productRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState is! AuthAuthenticated) return Future.value([]);
  return repo.getCategories(authState.user.businessId);
});

/// Currently selected category chip in inventory / POS.
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

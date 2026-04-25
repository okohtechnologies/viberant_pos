import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/states/auth_state.dart';
import 'auth_provider.dart';
import 'inventory_provider.dart';

export 'inventory_provider.dart';

final productsProvider = StreamProvider.autoDispose<List<ProductEntity>>((ref) {
  final repo = ref.read(productRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState is! AuthAuthenticated) return const Stream.empty();
  return repo.getProductsStream(authState.user.businessId);
});

final lowStockProductsProvider =
    StreamProvider.autoDispose<List<ProductEntity>>((ref) {
      final repo = ref.read(productRepositoryProvider);
      final authState = ref.watch(authProvider);

      if (authState is! AuthAuthenticated) return const Stream.empty();
      return repo.getLowStockProducts(authState.user.businessId);
    });

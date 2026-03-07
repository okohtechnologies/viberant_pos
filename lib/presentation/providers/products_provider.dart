// lib/presentation/providers/products_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart';
import 'package:viberant_pos/presentation/providers/inventory_provider.dart';
import '../../domain/entities/product_entity.dart';

final productsProvider = StreamProvider.autoDispose<List<ProductEntity>>((ref) {
  final productRepository = ref.read(productRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState is AuthAuthenticated) {
    final businessId = authState.user.businessId;
    return productRepository.getProductsStream(businessId);
  }

  return const Stream.empty();
});

final lowStockProductsProvider =
    StreamProvider.autoDispose<List<ProductEntity>>((ref) {
      final productRepository = ref.read(productRepositoryProvider);
      final authState = ref.watch(authProvider);

      if (authState is AuthAuthenticated) {
        final businessId = authState.user.businessId;
        return productRepository.getLowStockProducts(businessId);
      }

      return const Stream.empty();
    });

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/sale_repository.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/sale_entity.dart';
export '../providers/sale_repository_provider.dart' show saleRepositoryProvider;

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemEntity>>((
  ref,
) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItemEntity>> {
  CartNotifier() : super([]);

  void addProduct(ProductEntity product, {int quantity = 1, String? notes}) {
    final idx = state.indexWhere((i) => i.product.id == product.id);
    if (idx != -1) {
      final updated = state[idx].copyWith(
        quantity: state[idx].quantity + quantity,
        notes: notes ?? state[idx].notes,
      );
      state = [...state]..[idx] = updated;
    } else {
      state = [
        ...state,
        CartItemEntity(product: product, quantity: quantity, notes: notes),
      ];
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeProduct(productId);
      return;
    }
    final idx = state.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      state = [...state]..[idx] = state[idx].copyWith(quantity: newQuantity);
    }
  }

  void removeProduct(String productId) =>
      state = state.where((i) => i.product.id != productId).toList();

  void clearCart() => state = [];

  double get subtotal => state.fold(0, (s, i) => s + i.subtotal);
  double get taxAmount => subtotal * 0.03;
  double get totalAmount => subtotal + taxAmount;
  int get totalItems => state.fold(0, (s, i) => s + i.quantity);

  Future<SaleEntity> processPayment({
    required String businessId,
    required String cashierId,
    required String cashierName,
    required PaymentMethod paymentMethod,
    required SaleRepository saleRepository,
    String? customerId,
    String? customerName,
  }) async {
    if (state.isEmpty) throw Exception('Cart is empty');

    final sale = SaleEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      items: List.from(state),
      totalAmount: subtotal,
      taxAmount: taxAmount,
      discountAmount: 0.0,
      finalAmount: totalAmount,
      paymentMethod: paymentMethod,
      customerId: customerId,
      customerName: customerName,
      saleDate: DateTime.now(),
      businessId: businessId,
      cashierId: cashierId,
      cashierName: cashierName,
      status: SaleStatus.completed,
    );

    try {
      await saleRepository.processSale(sale);
      clearCart();
      debugPrint('✅ Payment processed: ${sale.transactionId}');
      return sale;
    } catch (e) {
      debugPrint('❌ Payment failed: $e');
      rethrow;
    }
  }
}

/// Derived summary — no Firestore reads, purely computed
final cartSummaryProvider = Provider<CartSummary>((ref) {
  final cart = ref.watch(cartProvider);
  final subtotal = cart.fold(0.0, (s, i) => s + i.subtotal);
  final tax = subtotal * 0.03;
  return CartSummary(
    subtotal: subtotal,
    taxAmount: tax,
    totalAmount: subtotal + tax,
    totalItems: cart.fold(0, (s, i) => s + i.quantity),
  );
});

class CartSummary {
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final int totalItems;

  CartSummary({
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.totalItems,
  });
}

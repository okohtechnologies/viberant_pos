// lib/presentation/providers/pos/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../../data/repositories/sale_repository.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/sale_entity.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemEntity>>((
  ref,
) {
  return CartNotifier();
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository();
});

class CartNotifier extends StateNotifier<List<CartItemEntity>> {
  CartNotifier() : super([]);

  void addProduct(ProductEntity product, {int quantity = 1, String? notes}) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex != -1) {
      final updatedItem = state[existingIndex].copyWith(
        quantity: state[existingIndex].quantity + quantity,
        notes: notes ?? state[existingIndex].notes,
      );
      state = [...state]..[existingIndex] = updatedItem;
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
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      state = [...state]
        ..[index] = state[index].copyWith(quantity: newQuantity);
    }
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() => state = [];

  double get subtotal => state.fold(0, (sum, item) => sum + item.subtotal);
  double get taxAmount => subtotal * 0.03;
  double get totalAmount => subtotal + taxAmount;
  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);

  /// Process payment and return the created sale
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
    print('📌 Processing sale for business: ${businessId}');
    print('📌 Cashier: ${cashierName} (ID: ${cashierId})');

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
      // Save the sale to database
      await saleRepository.processSale(sale);

      // Clear cart
      clearCart();

      print('✅ Payment processed and cart cleared');

      // Return the sale for receipt generation
      return sale;
    } catch (e, stackTrace) {
      print('❌ Payment failed: $e');
      print(stackTrace);
      rethrow;
    }
  }
}

/// Cart summary
final cartSummaryProvider = Provider<CartSummary>((ref) {
  final cart = ref.watch(cartProvider);
  final subtotal = cart.fold(0.0, (sum, item) => sum + item.subtotal);
  final taxAmount = subtotal * 0.03;
  final totalAmount = subtotal + taxAmount;
  final totalItems = cart.fold(0, (sum, item) => sum + item.quantity);

  return CartSummary(
    subtotal: subtotal,
    taxAmount: taxAmount,
    totalAmount: totalAmount,
    totalItems: totalItems,
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

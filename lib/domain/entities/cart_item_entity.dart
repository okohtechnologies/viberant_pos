// lib/domain/entities/cart_item_entity.dart
import 'package:viberant_pos/domain/entities/product_entity.dart';

class CartItemEntity {
  final ProductEntity product;
  int quantity;
  final String? notes;

  CartItemEntity({required this.product, required this.quantity, this.notes});

  double get subtotal => product.price * quantity;

  /// Ensure we keep the Firestore document ID when mapping
  factory CartItemEntity.fromMap(Map<String, dynamic> map) {
    final productMap = Map<String, dynamic>.from(map['product'] ?? {});
    final productId = productMap['id']?.toString() ?? '';

    return CartItemEntity(
      product: ProductEntity.fromMap(productMap, productId),
      quantity: (map['quantity'] ?? 1).toInt(),
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      if (notes != null) 'notes': notes,
    };
  }

  CartItemEntity copyWith({int? quantity, String? notes}) {
    return CartItemEntity(
      product: product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemEntity && other.product.id == product.id;
  }

  @override
  int get hashCode => product.id.hashCode;

  @override
  String toString() {
    return 'CartItemEntity(product: ${product.name}, quantity: $quantity, subtotal: $subtotal)';
  }
}

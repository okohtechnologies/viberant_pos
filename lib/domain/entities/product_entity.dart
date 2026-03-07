// lib/domain/entities/product_entity.dart - Update with new fields
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';

class ProductEntity {
  final String id;
  final String name;
  final String description;
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final String? barcode;
  final String? imageUrl;
  final String category;
  final String? supplier;
  final String? sku;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.minStock,
    this.barcode,
    this.imageUrl,
    required this.category,
    this.supplier,
    this.sku,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  // ---- fromFirestore ----
  factory ProductEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductEntity.fromMap(data, doc.id);
  }

  // ---- fromMap ----
  factory ProductEntity.fromMap(Map<String, dynamic> map, String id) {
    return ProductEntity(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      costPrice: (map['costPrice'] ?? 0.0).toDouble(),
      stock: (map['stock'] ?? 0).toInt(),
      minStock: (map['minStock'] ?? 5).toInt(),
      barcode: map['barcode'],
      imageUrl: map['imageUrl'],
      category: map['category'] ?? 'General',
      supplier: map['supplier'],
      sku: map['sku'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  // ---- toMap ----
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'minStock': minStock,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'category': category,
      'supplier': supplier,
      'sku': sku,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // ---- copyWith ----
  ProductEntity copyWith({
    String? name,
    String? description,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    String? barcode,
    String? imageUrl,
    String? category,
    String? supplier,
    String? sku,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ProductEntity(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
      sku: sku ?? this.sku,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // ---- Helper Methods ----
  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock == 0;
  double get profitMargin => price - costPrice;
  double get profitMarginPercentage =>
      costPrice > 0 ? ((price - costPrice) / costPrice) * 100 : 0;
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  Color get stockStatusColor {
    if (isOutOfStock) return ViberantColors.error;
    if (isLowStock) return ViberantColors.warning;
    return ViberantColors.success;
  }

  @override
  String toString() {
    return 'ProductEntity(id: $id, name: $name, price: $price, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

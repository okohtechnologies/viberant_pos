// lib/domain/entities/searchable_product_entity.dart
import './product_entity.dart';

class SearchableProductEntity {
  final ProductEntity product;
  final List<String> searchKeywords;

  SearchableProductEntity({required this.product, List<String>? searchKeywords})
    : searchKeywords = searchKeywords ?? _generateSearchKeywords(product);

  factory SearchableProductEntity.fromProduct(ProductEntity product) {
    return SearchableProductEntity(product: product);
  }

  static List<String> _generateSearchKeywords(ProductEntity product) {
    final keywords = <String>{};

    // Add name parts
    keywords.addAll(product.name.toLowerCase().split(' '));
    keywords.add(product.name.toLowerCase());

    // Add description parts
    if (product.description.isNotEmpty) {
      keywords.addAll(product.description.toLowerCase().split(' ').take(5));
      keywords.add(product.description.toLowerCase());
    }

    // Add category
    keywords.add(product.category.toLowerCase());

    // Add barcode if exists
    if (product.barcode != null && product.barcode!.isNotEmpty) {
      keywords.add(product.barcode!.toLowerCase());
    }

    // Add SKU if exists
    if (product.sku != null && product.sku!.isNotEmpty) {
      keywords.add(product.sku!.toLowerCase());
    }

    // Add supplier if exists
    if (product.supplier != null && product.supplier!.isNotEmpty) {
      keywords.add(product.supplier!.toLowerCase());
    }

    return keywords.toList();
  }

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;

    final searchLower = query.toLowerCase();
    return searchKeywords.any((keyword) => keyword.contains(searchLower));
  }

  // Convert back to ProductEntity
  ProductEntity toProductEntity() => product;
}

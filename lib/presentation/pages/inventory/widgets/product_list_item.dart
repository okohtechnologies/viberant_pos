// lib/presentation/pages/inventory/widgets/product_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/product_entity.dart';

class ProductListItem extends ConsumerStatefulWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  final ValueChanged<int> onStockUpdate;
  final bool isMobile;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.onStockUpdate,
    required this.isMobile,
  });

  @override
  ConsumerState<ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends ConsumerState<ProductListItem> {
  bool _isUpdatingStock = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isMobile = widget.isMobile;

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
        leading: _buildProductImage(product, isMobile),
        title: _buildProductTitle(product, isMobile),
        subtitle: _buildProductSubtitle(product, isMobile),
        trailing: _buildStockSection(product, isMobile),
        onTap: widget.onTap,
      ),
    );
  }

  Widget _buildProductImage(ProductEntity product, bool isMobile) {
    final size = isMobile ? 40.0 : 50.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ViberantColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: product.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderIcon(isMobile),
              ),
            )
          : _buildPlaceholderIcon(isMobile),
    );
  }

  Widget _buildPlaceholderIcon(bool isMobile) {
    return Icon(
      Icons.inventory_2_rounded,
      color: ViberantColors.primary,
      size: isMobile ? 20 : 24,
    );
  }

  Widget _buildProductTitle(ProductEntity product, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2),
        Text(
          product.category,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 10 : 12,
            color: ViberantColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProductSubtitle(ProductEntity product, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GHS ${NumberFormat('#,###.00').format(product.price)}',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w700,
            color: ViberantColors.primary,
          ),
        ),
        if (product.sku != null) ...[
          SizedBox(height: 2),
          Text(
            'SKU: ${product.sku!}',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 9 : 11,
              color: ViberantColors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockSection(ProductEntity product, bool isMobile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stock Status Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 8,
            vertical: isMobile ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: product.stockStatusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: product.stockStatusColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            product.stockStatus,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 8 : 10,
              fontWeight: FontWeight.w600,
              color: product.stockStatusColor,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 4 : 8),

        // Stock Controls
        _buildStockControls(product, isMobile),
      ],
    );
  }

  Widget _buildStockControls(ProductEntity product, bool isMobile) {
    if (_isUpdatingStock) {
      return SizedBox(
        width: isMobile ? 16 : 20,
        height: isMobile ? 16 : 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrease Stock
        _StockButton(
          icon: Icons.remove_rounded,
          onTap: () => _updateStock(product.stock - 1),
          isDisabled: product.stock <= 0,
          isMobile: isMobile,
        ),

        // Stock Display
        Container(
          width: isMobile ? 30 : 40,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
          child: Text(
            product.stock.toString(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),

        // Increase Stock
        _StockButton(
          icon: Icons.add_rounded,
          onTap: () => _updateStock(product.stock + 1),
          isMobile: isMobile,
        ),
      ],
    );
  }

  Future<void> _updateStock(int newStock) async {
    if (newStock < 0) return;

    setState(() {
      _isUpdatingStock = true;
    });

    try {
      widget.onStockUpdate(newStock);
      await Future.delayed(Duration(milliseconds: 300));
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStock = false;
        });
      }
    }
  }
}

class _StockButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isMobile;

  const _StockButton({
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final size = isMobile ? 20.0 : 24.0;
    final iconSize = isMobile ? 12.0 : 14.0;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDisabled
              ? ViberantColors.grey.withValues(alpha: 0.2)
              : ViberantColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: isDisabled ? ViberantColors.grey : ViberantColors.primary,
        ),
      ),
    );
  }
}

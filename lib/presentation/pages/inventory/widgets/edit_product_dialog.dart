// lib/presentation/pages/inventory/widgets/edit_product_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../providers/product_repository_provider.dart';

class EditProductDialog extends ConsumerStatefulWidget {
  final ProductEntity product;
  final String businessId;
  final VoidCallback onProductUpdated;
  final bool isMobile;

  const EditProductDialog({
    super.key,
    required this.product,
    required this.businessId,
    required this.onProductUpdated,
    required this.isMobile,
  });

  @override
  ConsumerState<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _barcodeController;
  late TextEditingController _skuController;
  late TextEditingController _supplierController;

  late String _selectedCategory;
  bool _isLoading = false;
  bool _isDeleting = false;

  final List<String> _categories = [
    'General',
    'Electronics',
    'Clothing',
    'Food & Beverages',
    'Home & Garden',
    'Health & Beauty',
    'Sports',
    'Books',
    'Toys',
    'Automotive',
  ];

  @override
  void initState() {
    super.initState();
    final product = widget.product;

    _nameController = TextEditingController(text: product.name);
    _descriptionController = TextEditingController(text: product.description);
    _priceController = TextEditingController(text: product.price.toString());
    _costPriceController = TextEditingController(
      text: product.costPrice.toString(),
    );
    _stockController = TextEditingController(text: product.stock.toString());
    _minStockController = TextEditingController(
      text: product.minStock.toString(),
    );
    _barcodeController = TextEditingController(text: product.barcode ?? '');
    _skuController = TextEditingController(text: product.sku ?? '');
    _supplierController = TextEditingController(text: product.supplier ?? '');
    _selectedCategory = product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(widget.isMobile ? 16 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.isMobile ? 400 : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: AlertDialog(
          title: Text(
            'Edit Product',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Product Name *',
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    isMobile: widget.isMobile,
                  ),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 2,
                    isMobile: widget.isMobile,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Selling Price *',
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            final price = double.tryParse(value!);
                            if (price == null || price <= 0) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                          isMobile: widget.isMobile,
                        ),
                      ),
                      SizedBox(width: widget.isMobile ? 8 : 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _costPriceController,
                          label: 'Cost Price',
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          isMobile: widget.isMobile,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _stockController,
                          label: 'Current Stock',
                          keyboardType: TextInputType.number,
                          isMobile: widget.isMobile,
                        ),
                      ),
                      SizedBox(width: widget.isMobile ? 8 : 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _minStockController,
                          label: 'Min Stock',
                          keyboardType: TextInputType.number,
                          isMobile: widget.isMobile,
                        ),
                      ),
                    ],
                  ),
                  _buildDropdown(
                    value: _selectedCategory,
                    items: _categories,
                    label: 'Category',
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value!),
                    isMobile: widget.isMobile,
                  ),
                  _buildTextField(
                    controller: _skuController,
                    label: 'SKU (Optional)',
                    isMobile: widget.isMobile,
                  ),
                  _buildTextField(
                    controller: _barcodeController,
                    label: 'Barcode (Optional)',
                    isMobile: widget.isMobile,
                  ),
                  _buildTextField(
                    controller: _supplierController,
                    label: 'Supplier (Optional)',
                    isMobile: widget.isMobile,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Delete Button
            TextButton(
              onPressed: _isLoading || _isDeleting ? null : _deleteProduct,
              style: TextButton.styleFrom(
                foregroundColor: ViberantColors.error,
              ),
              child: _isDeleting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Delete'),
            ),

            // Cancel Button
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),

            // Update Button
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProduct,
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(fontSize: isMobile ? 14 : 16),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 12 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(
              category,
              style: GoogleFonts.inter(fontSize: isMobile ? 14 : 16),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: isMobile ? 14 : 16),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 12 : 16,
          ),
        ),
      ),
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final productRepository = ref.read(productRepositoryProvider);

      final updatedProduct = widget.product.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        category: _selectedCategory,
        supplier: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await productRepository.updateProduct(widget.businessId, updatedProduct);

      if (mounted) {
        Navigator.pop(context);
        widget.onProductUpdated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: ViberantColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: $e'),
            backgroundColor: ViberantColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${widget.product.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ViberantColors.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final productRepository = ref.read(productRepositoryProvider);
      await productRepository.deleteProduct(
        widget.businessId,
        widget.product.id,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onProductUpdated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product deleted successfully!'),
            backgroundColor: ViberantColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: $e'),
            backgroundColor: ViberantColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}

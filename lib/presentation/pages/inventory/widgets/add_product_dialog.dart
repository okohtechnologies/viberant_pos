// lib/presentation/pages/inventory/widgets/add_product_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../providers/product_repository_provider.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  final String businessId;
  final VoidCallback onProductAdded;
  final bool isMobile;

  const AddProductDialog({
    super.key,
    required this.businessId,
    required this.onProductAdded,
    required this.isMobile,
  });

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '5');
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _supplierController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isLoading = false;

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
            'Add New Product',
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
                          label: 'Initial Stock',
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
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _addProduct,
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Add Product'),
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

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final productRepository = ref.read(productRepositoryProvider);

      final product = ProductEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        imageUrl: null,
        category: _selectedCategory,
        supplier: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await productRepository.addProduct(widget.businessId, product);

      if (mounted) {
        Navigator.pop(context);
        widget.onProductAdded();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: ViberantColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e'),
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
}

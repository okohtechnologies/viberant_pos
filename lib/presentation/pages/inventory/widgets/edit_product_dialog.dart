// lib/presentation/pages/inventory/widgets/edit_product_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/states/auth_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/inventory_provider.dart';

class EditProductDialog extends ConsumerStatefulWidget {
  final ProductEntity product;
  const EditProductDialog({super.key, required this.product});

  @override
  ConsumerState<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _supplierCtrl;
  late bool _isActive;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p.name);
    _descCtrl = TextEditingController(text: p.description);
    _priceCtrl = TextEditingController(text: p.price.toStringAsFixed(2));
    _costCtrl = TextEditingController(text: p.costPrice.toStringAsFixed(2));
    _stockCtrl = TextEditingController(text: '${p.stock}');
    _minStockCtrl = TextEditingController(text: '${p.minStock}');
    _categoryCtrl = TextEditingController(text: p.category);
    _skuCtrl = TextEditingController(text: p.sku ?? '');
    _supplierCtrl = TextEditingController(text: p.supplier ?? '');
    _isActive = p.isActive;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _priceCtrl,
      _costCtrl,
      _stockCtrl,
      _minStockCtrl,
      _categoryCtrl,
      _skuCtrl,
      _supplierCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(productRepositoryProvider);
      final updated = widget.product.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        costPrice: double.parse(_costCtrl.text.trim()),
        stock: int.parse(_stockCtrl.text.trim()),
        minStock: int.parse(_minStockCtrl.text.trim()),
        category: _categoryCtrl.text.trim().isNotEmpty
            ? _categoryCtrl.text.trim()
            : 'General',
        sku: _skuCtrl.text.trim().isNotEmpty ? _skuCtrl.text.trim() : null,
        supplier: _supplierCtrl.text.trim().isNotEmpty
            ? _supplierCtrl.text.trim()
            : null,
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );
      await repo.updateProduct(auth.user.businessId, updated);
      ref.invalidate(categoriesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _delete() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Product',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Delete "${widget.product.name}"? This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.deleteProduct(auth.user.businessId, widget.product.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ViberantRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Product',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: scheme.error,
                            ),
                            onPressed: _isLoading ? null : _delete,
                            tooltip: 'Delete product',
                            style: IconButton.styleFrom(
                              backgroundColor: scheme.errorContainer.withValues(
                                alpha: 0.4,
                              ),
                              padding: const EdgeInsets.all(6),
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: scheme.surfaceContainerHigh,
                              padding: const EdgeInsets.all(6),
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(ViberantRadius.md),
                      ),
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  _label('Product Name *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'Product name'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 12),
                  _label('Description'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Optional'),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _numField(
                          _priceCtrl,
                          'Selling Price (GHS) *',
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_costCtrl, 'Cost Price (GHS)')),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _numField(
                          _stockCtrl,
                          'Stock Quantity *',
                          isInt: true,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numField(
                          _minStockCtrl,
                          'Low Stock Alert',
                          isInt: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Category'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _categoryCtrl,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Beverages',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('SKU'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _skuCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Optional',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _label('Supplier'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _supplierCtrl,
                    decoration: const InputDecoration(hintText: 'Optional'),
                  ),

                  const SizedBox(height: 12),
                  // Active toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            'Inactive products won\'t appear in POS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeColor: scheme.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _numField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    bool isInt = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: isInt ? '0' : '0.00'),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return 'Required';
            }
            if (v != null && v.isNotEmpty) {
              if (isInt && int.tryParse(v) == null) return 'Invalid';
              if (!isInt && double.tryParse(v) == null) return 'Invalid';
            }
            return null;
          },
        ),
      ],
    );
  }
}

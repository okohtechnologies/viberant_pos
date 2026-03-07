// lib/presentation/pages/reports/sales_report_page.dart
// ignore_for_file: unused_field, unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/core/services/receipt_service.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../providers/auth_provider.dart';

// Provider for sales report data
final salesReportProvider = StreamProvider.autoDispose<List<SaleEntity>>((ref) {
  final authState = ref.watch(authProvider);
  final repository = SaleRepository();

  if (authState is! AuthAuthenticated) {
    return const Stream.empty();
  }

  return repository.getSalesStream(authState.user.businessId);
});

class SalesReportScreen extends ConsumerStatefulWidget {
  final String businessId;

  const SalesReportScreen({super.key, required this.businessId});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  PaymentMethod? _selectedPaymentMethod;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SaleEntity> _filterSales(List<SaleEntity> sales) {
    if (_searchQuery.isEmpty) return sales;

    final lowerQuery = _searchQuery.toLowerCase();
    return sales.where((sale) {
      return sale.transactionId.toLowerCase().contains(lowerQuery) ||
          sale.cashierName.toLowerCase().contains(lowerQuery) ||
          (sale.customerName?.toLowerCase().contains(lowerQuery) ?? false) ||
          _formatPaymentMethod(
            sale.paymentMethod,
          ).toLowerCase().contains(lowerQuery);
    }).toList();
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.momo:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.momo:
        return Icons.phone_android_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.credit:
        return Icons.receipt_long_rounded;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _selectedPaymentMethod = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesReportProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ');

    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            floating: true,
            elevation: 0,
            backgroundColor: ViberantColors.surface,
            title: Text(
              'Sales Reports',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ViberantColors.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: _exportReports,
                tooltip: 'Export Reports',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  ref.invalidate(salesReportProvider);
                },
                tooltip: 'Refresh',
              ),
            ],
          ),

          // Filters Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: ViberantColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ViberantColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date Range
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ViberantColors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _selectDate(context, true),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ViberantColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: ViberantColors.grey.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _startDate != null
                                            ? dateFormat.format(_startDate!)
                                            : 'Select Date',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
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
                              Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ViberantColors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _selectDate(context, false),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ViberantColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: ViberantColors.grey.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _endDate != null
                                            ? dateFormat.format(_endDate!)
                                            : 'Select Date',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search sales...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: ViberantColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sales List
          salesAsync.when(
            data: (sales) {
              final filteredSales = _filterSales(sales);

              if (filteredSales.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_rounded,
                            size: 64,
                            color: ViberantColors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No sales found',
                            style: TextStyle(
                              fontSize: 16,
                              color: ViberantColors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              'Try changing your search or filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: ViberantColors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final sale = filteredSales[index];
                    final statusColor = sale.status == SaleStatus.completed
                        ? ViberantColors.success
                        : sale.status == SaleStatus.pending
                        ? ViberantColors.warning
                        : ViberantColors.error;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: ViberantColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ViberantColors.background,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sale.transactionId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                        ).format(sale.saleDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ViberantColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    sale.status
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Details
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDetailItem(
                                      'Cashier',
                                      sale.cashierName,
                                      Icons.person_rounded,
                                    ),
                                    _buildDetailItem(
                                      'Payment',
                                      _formatPaymentMethod(sale.paymentMethod),
                                      _getPaymentMethodIcon(sale.paymentMethod),
                                    ),
                                    _buildDetailItem(
                                      'Items',
                                      '${sale.totalItems}',
                                      Icons.shopping_cart_rounded,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Customer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ViberantColors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          sale.customerName ??
                                              'Walk-in Customer',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Total',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ViberantColors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currencyFormat.format(
                                            sale.finalAmount,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: ViberantColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Footer Actions
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ViberantColors.background.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _viewSaleDetails(sale),
                                    icon: const Icon(
                                      Icons.remove_red_eye_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('View Details'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: ViberantColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        ReceiptService.generateAndShareReceipt(
                                          sale,
                                          context,
                                        ),
                                    icon: const Icon(
                                      Icons.receipt_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Re-Print'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ViberantColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: filteredSales.length),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: ViberantColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load sales',
                        style: TextStyle(color: ViberantColors.error),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: ViberantColors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: ViberantColors.grey),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: ViberantColors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _exportReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Reports'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Export options:'),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('PDF Report'),
            ),
            ListTile(
              leading: Icon(Icons.table_chart),
              title: Text('Excel/CSV'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement export
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _viewSaleDetails(SaleEntity sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sale Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Transaction: ${sale.transactionId}'),
              Text(
                'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)}',
              ),
              Text('Cashier: ${sale.cashierName}'),
              if (sale.customerName != null)
                Text('Customer: ${sale.customerName}'),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...sale.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.circle, size: 8),
                  title: Text(item.product.name),
                  subtitle: Text('Quantity: ${item.quantity}'),
                  trailing: Text(
                    NumberFormat.currency(symbol: 'GHS ').format(item.subtotal),
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:'),
                  Text(
                    NumberFormat.currency(
                      symbol: 'GHS ',
                    ).format(sale.finalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _reprintReceipt(SaleEntity sale) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Printing receipt for ${sale.transactionId}')),
    );
  }
}

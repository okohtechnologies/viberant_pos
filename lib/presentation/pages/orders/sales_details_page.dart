// lib/presentation/pages/orders/sales_details_page.dart
// ignore_for_file: unreachable_switch_default, unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';
import 'package:viberant_pos/domain/entities/sale_entity.dart';
import 'package:viberant_pos/domain/entities/cart_item_entity.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart'; // Import your auth provider

class SaleDetailsPage extends ConsumerWidget {
  // Changed to ConsumerWidget
  final SaleEntity sale;

  const SaleDetailsPage({super.key, required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef
    // Get current user from auth provider
    final authState = ref.watch(authProvider);
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    // Calculate total profit (only for admin)
    double totalCost = 0;
    double totalProfit = 0;

    if (isAdmin) {
      for (var item in sale.items) {
        double itemCost = item.product.costPrice * item.quantity;
        double itemProfit =
            (item.product.price * item.quantity) -
            itemCost; // FIXED: Use item price not total sale
        totalCost += itemCost;
        totalProfit += itemProfit;
      }
    }

    return Scaffold(
      backgroundColor: ViberantColors.background,
      appBar: AppBar(
        title: const Text('Sale Details'),
        backgroundColor: ViberantColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sale Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Receipt Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ViberantColors.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              sale.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(sale.status),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(sale.status),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transaction ID: ${sale.transactionId}',
                      style: TextStyle(
                        color: ViberantColors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MMM/yyyy – hh:mm a').format(sale.saleDate),
                      style: TextStyle(color: ViberantColors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 34, 36, 37),
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              sale.customerName?.isNotEmpty == true
                                  ? sale.customerName!
                                  : 'Walk-in Customer',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ViberantColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Cashier',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 15, 16, 16),
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              sale.cashierName, // Use sale's cashier name instead of current user
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 50, 122, 204),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: ViberantColors.grey.withOpacity(0.3)),
                    const SizedBox(height: 16),

                    // Financial Breakdown (visible to all)
                    _buildFinancialRow('Total Sales', sale.totalAmount),
                    _buildFinancialRow('Tax', sale.taxAmount),
                    _buildFinancialRow('Discount', sale.discountAmount),

                    // Admin-only: Cost and Profit Breakdown
                    if (isAdmin) ...[
                      const SizedBox(height: 8),
                      Divider(color: ViberantColors.grey.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      _buildFinancialRow('Total Cost', totalCost),
                      _buildFinancialRow(
                        'Gross Profit',
                        totalProfit,
                        isProfit: true,
                      ),
                    ],

                    const SizedBox(height: 16),
                    Divider(color: ViberantColors.grey.withOpacity(0.3)),
                    const SizedBox(height: 16),

                    // Final Amount (visible to all)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Final Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₵${NumberFormat('#,###.00').format(sale.finalAmount)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ViberantColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Items List Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items Sold (${sale.totalItems})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ViberantColors.onSurface,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₵${NumberFormat('#,###.00').format(sale.totalAmount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ViberantColors.primary,
                              ),
                            ),
                            // Admin-only: Profit display
                            if (isAdmin)
                              Text(
                                'Profit: ₵${NumberFormat('#,###.00').format(totalProfit)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: totalProfit >= 0
                                      ? ViberantColors.success
                                      : ViberantColors.error,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sale.items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = sale.items[index];
                        return _buildItemRow(item, index + 1, isAdmin);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Information Card (visible to all)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ViberantColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getPaymentMethodColor(
                              sale.paymentMethod,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getPaymentMethodIcon(sale.paymentMethod),
                            color: _getPaymentMethodColor(sale.paymentMethod),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getPaymentMethodText(sale.paymentMethod),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Payment completed successfully',
                                style: TextStyle(
                                  color: ViberantColors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₵${NumberFormat('#,###.00').format(sale.finalAmount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: ViberantColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Product Stock Information (visible to all - important for operations)
            if (_hasLowStockItems(sale)) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: ViberantColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock Alert',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ViberantColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...sale.items
                          .where(
                            (item) =>
                                item.product.isLowStock ||
                                item.product.isOutOfStock,
                          )
                          .map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: item.product.stockStatusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.product.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.product.stockStatus,
                                    style: TextStyle(
                                      color: item.product.stockStatusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${item.product.stock} left)',
                                    style: TextStyle(
                                      color: ViberantColors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                    ],
                  ),
                ),
              ),
            ],

            // Additional Information (Admin only)
            if (isAdmin) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings_rounded,
                            color: ViberantColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ViberantColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Business ID', sale.businessId),
                      _buildInfoRow('Cashier ID', sale.cashierId),
                      _buildInfoRow('Cashier Name', sale.cashierName),
                      _buildInfoRow('Sale ID', sale.id),
                      if (sale.customerId != null)
                        _buildInfoRow('Customer ID', sale.customerId!),
                      _buildInfoRow('Transaction ID', sale.transactionId),
                      _buildInfoRow(
                        'Sale Date',
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(sale.saleDate),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Helper widget for financial rows
  Widget _buildFinancialRow(
    String label,
    double amount, {
    bool isProfit = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: ViberantColors.grey)),
          Text(
            '₵${NumberFormat('#,###.00').format(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isProfit
                  ? (amount >= 0
                        ? ViberantColors.success
                        : ViberantColors.error)
                  : ViberantColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for item rows with conditional profit calculation
  Widget _buildItemRow(CartItemEntity item, int number, bool isAdmin) {
    double itemTotal = item.product.price * item.quantity;
    double itemCost = item.product.costPrice * item.quantity;
    double itemProfit = itemTotal - itemCost;
    double profitMarginPercentage = item.product.costPrice > 0
        ? ((itemTotal - itemCost) / itemCost) * 100
        : 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: ViberantColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ViberantColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ViberantColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} × ₵${NumberFormat('#,###.00').format(item.product.price)}',
                style: TextStyle(color: ViberantColors.grey, fontSize: 12),
              ),
              if (item.notes != null && item.notes!.isNotEmpty)
                Text(
                  'Notes: ${item.notes}',
                  style: TextStyle(
                    color: ViberantColors.grey,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₵${NumberFormat('#,###.00').format(itemTotal)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ViberantColors.primary,
              ),
            ),
            // Admin-only: Cost and profit details
            if (isAdmin) ...[
              const SizedBox(height: 2),
              Text(
                'Cost: ₵${NumberFormat('#,###.00').format(itemCost)}',
                style: TextStyle(color: ViberantColors.grey, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    itemProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: itemProfit >= 0
                        ? ViberantColors.success
                        : ViberantColors.error,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '₵${NumberFormat('#,###.00').format(itemProfit.abs())}',
                    style: TextStyle(
                      color: itemProfit >= 0
                          ? ViberantColors.success
                          : ViberantColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${profitMarginPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(color: ViberantColors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Helper widget for info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: ViberantColors.grey, fontSize: 12),
          ),
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ],
      ),
    );
  }

  // Check if any items are low on stock
  bool _hasLowStockItems(SaleEntity sale) {
    return sale.items.any(
      (item) => item.product.isLowStock || item.product.isOutOfStock,
    );
  }

  // Helper methods for display
  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.momo:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card Payment';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.credit:
        return 'Customer Credit';
      default:
        return 'Cash';
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.attach_money_rounded;
      case PaymentMethod.momo:
        return Icons.phone_android_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.credit:
        return Icons.receipt_long_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return ViberantColors.success;
      case PaymentMethod.momo:
        return Colors.purple;
      case PaymentMethod.card:
        return Colors.blue;
      case PaymentMethod.bankTransfer:
        return Colors.orange;
      case PaymentMethod.credit:
        return Colors.red;
      default:
        return ViberantColors.grey;
    }
  }

  String _getStatusText(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed:
        return 'Completed';
      case SaleStatus.pending:
        return 'Pending';
      case SaleStatus.refunded:
        return 'Refunded';
      case SaleStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Completed';
    }
  }

  Color _getStatusColor(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed:
        return ViberantColors.success;
      case SaleStatus.pending:
        return ViberantColors.warning;
      case SaleStatus.refunded:
        return ViberantColors.info ?? Colors.blue;
      case SaleStatus.cancelled:
        return ViberantColors.error;
      default:
        return ViberantColors.grey;
    }
  }
}

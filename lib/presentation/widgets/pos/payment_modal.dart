// lib/presentation/widgets/pos/payment_modal.dart
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/core/services/receipt_service.dart';
import 'package:viberant_pos/presentation/providers/cart_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';

class PaymentModal extends ConsumerStatefulWidget {
  final double totalAmount;
  final VoidCallback onPaymentComplete;
  final String businessId;
  final String cashierId;
  final String cashierName;

  const PaymentModal({
    super.key,
    required this.totalAmount,
    required this.onPaymentComplete,
    required this.businessId,
    required this.cashierId,
    required this.cashierName,
  });

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;

  final Map<PaymentMethod, Map<String, dynamic>> _paymentMethods = {
    PaymentMethod.cash: {
      'name': 'Cash',
      'icon': Icons.money_rounded,
      'color': ViberantColors.success,
    },
    PaymentMethod.momo: {
      'name': 'Mobile Money',
      'icon': Icons.phone_android_rounded,
      'color': ViberantColors.primary,
    },
    PaymentMethod.card: {
      'name': 'Card',
      'icon': Icons.credit_card_rounded,
      'color': ViberantColors.warning,
    },
    PaymentMethod.bankTransfer: {
      'name': 'Bank Transfer',
      'icon': Icons.account_balance_rounded,
      'color': ViberantColors.secondary,
    },
    PaymentMethod.credit: {
      'name': 'Credit',
      'icon': Icons.receipt_long_rounded,
      'color': ViberantColors.error,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            "Process Payment",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Total Amount
          Text(
            'GHS ${NumberFormat('#,###.00').format(widget.totalAmount)}',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: ViberantColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Payment Methods
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: _paymentMethods.entries.map((entry) {
              final method = entry.key;
              final data = entry.value;
              final isSelected = _selectedMethod == method;

              return _PaymentMethodCard(
                name: data['name'] as String,
                icon: data['icon'] as IconData,
                color: data['color'] as Color,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedMethod = method),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing || _selectedMethod == null
                      ? null
                      : _confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedMethod == null
                        ? Colors.grey
                        : ViberantColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          "Confirm Payment",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // In your payment_modal.dart, update these methods:

  Future<void> _confirmPayment() async {
    if (_selectedMethod == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Method: ${_paymentMethods[_selectedMethod]!['name']}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Amount: GHS ${NumberFormat('#,###.00').format(widget.totalAmount)}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text("Are you sure you want to process this payment?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      // Process payment and get the sale object
      final sale = await _processPaymentWithTimeout();

      if (mounted) {
        Navigator.pop(context); // Close payment modal
        _showSuccessDialog(sale); // Pass the sale to the dialog
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<SaleEntity> _processPaymentWithTimeout() async {
    final cartNotifier = ref.read(cartProvider.notifier);
    final saleRepository = ref.read(saleRepositoryProvider);

    return await cartNotifier
        .processPayment(
          businessId: widget.businessId,
          cashierId: widget.cashierId,
          cashierName: widget.cashierName,
          paymentMethod: _selectedMethod!,
          saleRepository: saleRepository,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Payment processing timed out. Please try again.');
          },
        );
  }

  void _showSuccessDialog(SaleEntity sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: ViberantColors.success),
            const SizedBox(width: 8),
            const Text("Payment Successful"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Payment processed successfully!"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ViberantColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    "GHS ${NumberFormat('#,###.00').format(sale.finalAmount)}",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ViberantColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Transaction ID: ${sale.transactionId}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Items: ${sale.totalItems}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Via ${((sale.paymentMethod))}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              "Cashier: ${sale.cashierName}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          // Share Receipt Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close success dialog
              ReceiptService.generateAndShareReceipt(sale, context);
            },
            icon: const Icon(Icons.share, size: 20),
            label: const Text("Share Receipt"),
            style: ElevatedButton.styleFrom(
              backgroundColor: ViberantColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          // Done Button
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context); // Close success dialog
              widget.onPaymentComplete();
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    String errorMessage = _getUserFriendlyErrorMessage(error);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_rounded, color: ViberantColors.error),
            const SizedBox(width: 8),
            const Text("Payment Failed"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            const SizedBox(height: 12),
            const Text(
              "Please try again or contact support if the problem persists.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('Cart is empty')) {
      return 'Cannot process payment with empty cart. Please add items to cart.';
    } else if (error.contains('Insufficient stock')) {
      return 'Insufficient stock for some items. Please check inventory levels.';
    } else if (error.contains('timed out')) {
      return 'Payment processing took too long. Please check your internet connection.';
    } else if (error.contains('Firebase') || error.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'An error occurred while processing payment: ${error.split(':').last.trim()}';
    }
  }

  void _printReceipt() {
    // Implement receipt printing logic here
    print(
      '🖨️ Printing receipt for GHS ${NumberFormat('#,###.00').format(widget.totalAmount)}',
    );
    // You can use packages like:
    // - esc_pos_printer
    // - blue_thermal_printer
    // - flutter_usb_printer
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withOpacity(0.1) : ViberantColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : ViberantColors.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

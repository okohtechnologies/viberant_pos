// lib/core/services/receipt_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sale_entity.dart';

class ReceiptService {
  static Future<void> generateAndShareReceipt(
    SaleEntity sale,
    BuildContext context,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // Add timeout that auto-closes after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });

          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Generating receipt...'),
              ],
            ),
          );
        },
      );

      // Generate PDF
      final pdf = await _generateReceiptPdf(sale);
      final pdfBytes = await pdf.save();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/receipt_${sale.transactionId}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Share via WhatsApp or other apps
      await _shareReceiptFile(filePath, sale);
    } catch (e) {
      // Dismiss loading dialog if still showing
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Fallback to simple dialog
      if (context.mounted) {
        _showReceiptDialog(sale, context);
      }
    }
  }

  static Future<void> _shareReceiptFile(
    String filePath,
    SaleEntity sale,
  ) async {
    final text =
        '''
✅ Receipt from VIBERANT POS

Transaction: ${sale.transactionId}
Amount: GHS ${NumberFormat('#,###.00').format(sale.finalAmount)}
Date: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)}
Payment: ${_formatPaymentMethod(sale.paymentMethod)}

Thank you for your business!
''';

    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/pdf')],
      text: text,
      subject: 'Your Receipt - ${sale.transactionId}',
    );
  }

  static Future<pw.Document> _generateReceiptPdf(SaleEntity sale) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 *
              PdfPageFormat
                  .mm, // Slightly wider for better readability on phones
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'VIBERANT',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Point of Sale System',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // Transaction Info
              _infoRow('Transaction ID:', sale.transactionId),
              _infoRow('Date:', dateFormat.format(sale.saleDate)),
              _infoRow('Cashier:', sale.cashierName),

              if (sale.customerName != null && sale.customerName!.isNotEmpty)
                _infoRow('Customer:', sale.customerName!),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),

              // Items Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('ITEM', style: _boldStyle(fontSize: 11)),
                  ),
                  pw.Expanded(
                    child: pw.Text('QTY', style: _boldStyle(fontSize: 11)),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'AMOUNT',
                      style: _boldStyle(fontSize: 11),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 6),

              // Items List
              ...sale.items.map(
                (item) => pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            item.product.name,
                            style: _normalStyle(),
                            maxLines: 2,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            '${item.quantity}',
                            style: _normalStyle(),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            currencyFormat.format(
                              item.product.price * item.quantity,
                            ),
                            style: _normalStyle(),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(left: 4, top: 2),
                        child: pw.Text(
                          'Note: ${item.notes!}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 6),
                  ],
                ),
              ),

              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // Totals
              _totalRow('Subtotal:', sale.totalAmount, currencyFormat),
              _totalRow('Tax (3%):', sale.taxAmount, currencyFormat),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      currencyFormat.format(sale.finalAmount),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Payment Method
              pw.Center(
                child: pw.Text(
                  'Payment Method: ${_formatPaymentMethod(sale.paymentMethod)}',
                  style: _boldStyle(),
                ),
              ),
              pw.SizedBox(height: 12),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Please keep this receipt for your records',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Contact: info@viberantpos.com',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Helper methods
  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: _boldStyle()),
          pw.Text(value, style: _normalStyle()),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    double amount,
    NumberFormat currencyFormat,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: _normalStyle()),
          pw.Text(currencyFormat.format(amount), style: _normalStyle()),
        ],
      ),
    );
  }

  static pw.TextStyle _boldStyle({double fontSize = 10}) {
    return pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold);
  }

  static pw.TextStyle _normalStyle({double fontSize = 10}) {
    return pw.TextStyle(fontSize: fontSize);
  }

  static String _formatPaymentMethod(PaymentMethod method) {
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

  // Simple dialog for fallback (keep your existing _showReceiptDialog)
  static void _showReceiptDialog(SaleEntity sale, BuildContext context) {
    // Your existing dialog implementation
    // ...
  }

  // OPTIONAL: Quick preview method
  static Future<void> previewReceipt(SaleEntity sale) async {
    final pdf = await _generateReceiptPdf(sale);
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/receipt_preview.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Could open with a PDF viewer package
    // await OpenFile.open(filePath);
  }
}

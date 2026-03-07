// lib/domain/entities/sale_entity.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_entity.dart';

enum PaymentMethod { cash, momo, card, bankTransfer, credit }

enum SaleStatus { completed, pending, refunded, cancelled }

class SaleEntity {
  final String id;
  final String transactionId;
  final List<CartItemEntity> items;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final double finalAmount;
  final PaymentMethod paymentMethod;
  final String? customerId;
  final String? customerName;
  final DateTime saleDate;
  final String businessId;
  final String cashierId;
  final String cashierName;
  final SaleStatus status;

  const SaleEntity({
    required this.id,
    required this.transactionId,
    required this.items,
    required this.totalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentMethod,
    this.customerId,
    this.customerName,
    required this.saleDate,
    required this.businessId,
    required this.cashierId,
    required this.cashierName,
    required this.status,
  });

  // ---- fromFirestore ----
  factory SaleEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SaleEntity.fromMap(data, doc.id);
  }

  // ---- fromMap ----
  factory SaleEntity.fromMap(Map<String, dynamic> map, [String? id]) {
    try {
      // Safely parse items list
      List<CartItemEntity> itemsList = [];
      if (map['items'] is List) {
        itemsList = (map['items'] as List).map<CartItemEntity>((item) {
          return CartItemEntity.fromMap(item as Map<String, dynamic>);
        }).toList();
      }

      return SaleEntity(
        id: id ?? map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        transactionId: map['transactionId']?.toString() ?? '',
        items: itemsList,
        totalAmount: _parseDouble(map['totalAmount']),
        taxAmount: _parseDouble(map['taxAmount']),
        discountAmount: _parseDouble(map['discountAmount']),
        finalAmount: _parseDouble(map['finalAmount']),
        paymentMethod: _paymentMethodFromString(
          map['paymentMethod']?.toString(),
        ),
        customerId: map['customerId']?.toString(),
        customerName: map['customerName']?.toString(),
        saleDate: _parseDateTime(map['saleDate']),
        businessId: map['businessId']?.toString() ?? '',
        cashierId: map['cashierId']?.toString() ?? '',
        cashierName: map['cashierName']?.toString() ?? '',
        status: _saleStatusFromString(map['status']?.toString()),
      );
    } catch (e) {
      throw FormatException('Error parsing SaleEntity from map: $e');
    }
  }

  // ---- toMap ----
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'transactionId': transactionId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'paymentMethod': _paymentMethodToString(paymentMethod),
      'customerId': customerId,
      'customerName': customerName,
      'saleDate': Timestamp.fromDate(saleDate),
      'businessId': businessId,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'status': _saleStatusToString(status),
      'createdAt':
          FieldValue.serverTimestamp(), // Use server timestamp for consistency
    };
  }

  // ---- copyWith ----
  SaleEntity copyWith({
    String? id,
    String? transactionId,
    List<CartItemEntity>? items,
    double? totalAmount,
    double? taxAmount,
    double? discountAmount,
    double? finalAmount,
    PaymentMethod? paymentMethod,
    String? customerId,
    String? customerName,
    DateTime? saleDate,
    String? businessId,
    String? cashierId,
    String? cashierName,
    SaleStatus? status,
  }) {
    return SaleEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      saleDate: saleDate ?? this.saleDate,
      businessId: businessId ?? this.businessId,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      status: status ?? this.status,
    );
  }

  // Helper methods for safe parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // Helper methods for enum conversion
  static PaymentMethod _paymentMethodFromString(String? method) {
    switch (method?.toLowerCase()) {
      case 'momo':
        return PaymentMethod.momo;
      case 'card':
        return PaymentMethod.card;
      case 'banktransfer':
        return PaymentMethod.bankTransfer;
      case 'credit':
        return PaymentMethod.credit;
      default:
        return PaymentMethod.cash;
    }
  }

  static String _paymentMethodToString(PaymentMethod method) {
    return method.toString().split('.').last;
  }

  static SaleStatus _saleStatusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return SaleStatus.pending;
      case 'refunded':
        return SaleStatus.refunded;
      case 'cancelled':
        return SaleStatus.cancelled;
      default:
        return SaleStatus.completed;
    }
  }

  static String _saleStatusToString(SaleStatus status) {
    return status.toString().split('.').last;
  }

  // Helper getters
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  String get paymentMethodString => _paymentMethodToString(paymentMethod);

  // Equality check
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SaleEntity(id: $id, transactionId: $transactionId, totalAmount: $totalAmount, status: $status)';
  }
}

// lib/domain/entities/business_settings.dart
class BusinessSettings {
  final String currency;
  final String country;
  final double taxRate;
  final bool requireCustomerInfo;
  final bool lowStockAlerts;
  final bool autoBackup;
  final int receiptCopyCount;

  const BusinessSettings({
    required this.currency,
    required this.country,
    required this.taxRate,
    required this.requireCustomerInfo,
    required this.lowStockAlerts,
    required this.autoBackup,
    required this.receiptCopyCount,
  });

  // Default settings for new businesses
  factory BusinessSettings.defaultSettings() {
    return BusinessSettings(
      currency: 'GHS',
      country: 'Ghana',
      taxRate: 0.03, // 3%
      requireCustomerInfo: false,
      lowStockAlerts: true,
      autoBackup: true,
      receiptCopyCount: 1,
    );
  }

  // ---- fromMap ----
  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      currency: map['currency'] ?? 'GHS',
      country: map['country'] ?? 'Ghana',
      taxRate: (map['taxRate'] ?? 0.03).toDouble(),
      requireCustomerInfo: map['requireCustomerInfo'] ?? false,
      lowStockAlerts: map['lowStockAlerts'] ?? true,
      autoBackup: map['autoBackup'] ?? true,
      receiptCopyCount: map['receiptCopyCount'] ?? 1,
    );
  }

  // ---- toMap ----
  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'country': country,
      'taxRate': taxRate,
      'requireCustomerInfo': requireCustomerInfo,
      'lowStockAlerts': lowStockAlerts,
      'autoBackup': autoBackup,
      'receiptCopyCount': receiptCopyCount,
    };
  }

  // ---- copyWith ----
  BusinessSettings copyWith({
    String? currency,
    String? country,
    double? taxRate,
    bool? requireCustomerInfo,
    bool? lowStockAlerts,
    bool? autoBackup,
    int? receiptCopyCount,
  }) {
    return BusinessSettings(
      currency: currency ?? this.currency,
      country: country ?? this.country,
      taxRate: taxRate ?? this.taxRate,
      requireCustomerInfo: requireCustomerInfo ?? this.requireCustomerInfo,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      autoBackup: autoBackup ?? this.autoBackup,
      receiptCopyCount: receiptCopyCount ?? this.receiptCopyCount,
    );
  }

  @override
  String toString() {
    return 'BusinessSettings(currency: $currency, taxRate: $taxRate)';
  }
}
